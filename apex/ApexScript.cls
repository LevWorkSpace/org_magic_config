//Assign permission sets to users with specified profiles
final Map<String, Set<String>> USERS_PROFILE_TO_PERMISSION_SET = new Map<String, Set<String>> {
        'OCE Admin' => new Set<String> {'Meeting_Admin', 'Meeting_User', 'EmailAdministration',
                'TimeOffTerritoryAdministration', 'DocumentAdmin', 'ProductAdministration',
                'WeChatAdministration', 'InsightUser'},
        'Sales Representative' => new Set<String> {'Meeting_User', 'EmailUser', 'TimeOffTerritoryUser',
                'DocumentUser', 'ProductUser', 'WeChatUser', 'InsightUser'},
        'Medical Science Liaison' => new Set<String> {'InsightUser'}
};

//Add custom permissions to Profiles
final Map<String, Set<String>> PROFILE_TO_CUSTOM_PERMISSION = new Map<String, Set<String>> {
        'OCE Admin' => new Set<String> {'InsightCaptureFromAccount', 'InsightCaptureFromHome', 'InsightCaptureFromMeeting'},
        'Sales Representative' => new Set<String> {'InsightCaptureFromAccount', 'InsightCaptureFromHome', 'InsightCaptureFromMeeting'},
        'Medical Science Liaison' => new Set<String> {'InsightCaptureFromAccount', 'InsightCaptureFromHome', 'InsightCaptureFromMeeting'}
};

addCustomPermissionsToProfiles();
assignPermissionSetsProfileUsers();

//Permission Sets
void assignPermissionSetsProfileUsers() {
    //gather Permission Sets
    Set<String> permissionSetNames = gatherSets(USERS_PROFILE_TO_PERMISSION_SET.values());
    Map<String, Id> permissionSetNameToId = getPermissionSetNameToId(permissionSetNames);
    //gather Profile Users
    Map<String, Set<Id>> profileNameToUserIds = new Map<String, Set<Id>>();
    for (User user : [SELECT Id, Profile.Name FROM User WHERE Profile.Name IN :USERS_PROFILE_TO_PERMISSION_SET.keySet()]) {
        if (profileNameToUserIds.containsKey(user.Profile.Name)) {
            profileNameToUserIds.get(user.Profile.Name).add(user.Id);
        } else {
            profileNameToUserIds.put(user.Profile.Name, new Set<Id>{user.Id});
        }
    }
    //Assign all profiles users to specified permission sets
    List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();
    for (String profileName : USERS_PROFILE_TO_PERMISSION_SET.keySet()) {
        for (String permissionSetName : USERS_PROFILE_TO_PERMISSION_SET.get(profileName)) {
            for (Id userId : profileNameToUserIds.get(profileName)) {
                assignments.add(
                        new PermissionSetAssignment(
                                AssigneeId = userId,
                                PermissionSetId = permissionSetNameToId.get(permissionSetName)
                        )
                );
            }
        }
    }
    //Skip duplicates - already created assignments
    Database.SaveResult[] results = Database.insert(assignments, false);
    handleDBDuplicateResults(results);
}

//Custom Permissions
void addCustomPermissionsToProfiles() {
    Set<String> customPermissionsNames = gatherSets(PROFILE_TO_CUSTOM_PERMISSION.values());
    Map<String, Id> customPermissionNameToId = new Map<String, Id>();
    for (CustomPermission ps : [SELECT Id, DeveloperName FROM CustomPermission WHERE DeveloperName IN :customPermissionsNames]) {
        customPermissionNameToId.put(ps.DeveloperName, ps.Id);
    }
    //gather Profiles - custom permissions actually assigned not to the profile but to the PermissionSet record, which represents profile
    Map<String, Id> profileNameToId = new Map<String, Id>();
    for (PermissionSet profile : [SELECT Id, Profile.Name FROM PermissionSet where Profile.Name IN :PROFILE_TO_CUSTOM_PERMISSION.keySet()]) {
        profileNameToId.put(profile.Profile.Name, profile.Id);
    }
    List<SetupEntityAccess> accesses = new List<SetupEntityAccess>();
    for (String profileName : PROFILE_TO_CUSTOM_PERMISSION.keySet()) {
        for (String cpName : PROFILE_TO_CUSTOM_PERMISSION.get(profileName)) {
            accesses.add(
                    new SetupEntityAccess(
                            ParentId = profileNameToId.get(profileName),
                            SetupEntityId = customPermissionNameToId.get(cpName)
                    )
            );
        }
    }
    //Skip duplicates - already created accesses
    Database.SaveResult[] results = Database.insert(accesses, false);
    handleDBDuplicateResults(results);
}

Map<String, Id> getPermissionSetNameToId(Set<String> permissionSetNames) {

    Map<String, Id> permissionSetNameToId = new Map<String, Id>();
    for (PermissionSet ps : [SELECT Id, Name FROM PermissionSet WHERE Name IN :permissionSetNames]) {
        permissionSetNameToId.put(ps.Name, ps.Id);
    }
    return permissionSetNameToId;
}
Set<String> gatherSets(List<Set<String>> sets) {
    Set<String> totalSet = new Set<String>();
    for (Set<String> singleSet : sets) {
        totalSet.addAll(singleSet);
    }
    return totalSet;
}
void handleDBDuplicateResults(Database.SaveResult[] results) {
    for (Database.SaveResult recordResult : results) {
        if (!recordResult.isSuccess()) {
            for(Database.Error error : recordResult.getErrors()) {
                if (error.getStatusCode() != StatusCode.DUPLICATE_VALUE) {
                    System.debug(error.getStatusCode() + ': ' + error.getMessage());
                }
            }
        }
    }
}