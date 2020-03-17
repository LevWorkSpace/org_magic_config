//Script is using MetadataConfiguration constants
addCustomPermissionsToPermissionSets();
assignPermissionSetsToAdminAndSR();

Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
addDBSchemaRecords(mdContainer);
addUISchemaRecords(mdContainer);
addTriggerHandlerRecords(mdContainer);
addCustomMetadataQuickActionRecords(mdContainer);
addLayoutsMetadata(mdContainer);
Metadata.Operations.enqueueDeployment(mdContainer, null);


//Service methods
//Custom Metadata
void addDBSchemaRecords(Metadata.DeployContainer mdContainer) {
    for(sObject dbSchemaRecord : queryMetadata('DbSchema__mdt', DB_SCHEMA_TO_ACTIVATE)) {
        mdContainer.addMetadata(
            buildActiveMetadataRecord(dbSchemaRecord)
        );
    }
}

void addUISchemaRecords(Metadata.DeployContainer mdContainer) {
    for(sObject uiSchemaRecord : queryMetadata('UiSchema__mdt', UI_SCHEMA_TO_ACTIVATE)) {
        mdContainer.addMetadata(
                buildActiveMetadataRecord(uiSchemaRecord)
        );
    }
}

void addTriggerHandlerRecords(Metadata.DeployContainer mdContainer) {
    for(sObject triggerHandlerRecord : queryMetadata('TriggerHandler__mdt', TRIGGER_HANDLERS_TO_ACTIVATE)) {
        mdContainer.addMetadata(
            buildActiveMetadataRecord(triggerHandlerRecord)
        );
    }
}

void addCustomMetadataQuickActionRecords(Metadata.DeployContainer mdContainer) {
    for(sObject quickActionRecord : queryMetadata('QuickAction__mdt', QUICK_ACTIONS_TO_ACTIVATE)) {
        mdContainer.addMetadata(
            buildActiveMetadataRecord(quickActionRecord)
        );
    }
}

List<sObject> queryMetadata(String name, Set<String> recordNames) {
    return Database.query('SELECT Label,DeveloperName FROM ' + NAMESPACE + name + ' WHERE DeveloperName IN: recordNames');
}

Metadata.CustomMetadata buildActiveMetadataRecord(sObject metadataRecord) {
    Metadata.CustomMetadata customMetadata = new Metadata.CustomMetadata();
    customMetadata.fullName = metadataRecord.getSObjectType() + '.' + NAMESPACE + metadataRecord.get('DeveloperName');
    customMetadata.label = (String)metadataRecord.get('Label');

    Metadata.CustomMetadataValue activeField = new Metadata.CustomMetadataValue();
    activeField.field = NAMESPACE + 'IsActive__c';
    activeField.value = true;
    customMetadata.values.add(activeField);
    
    return customMetadata;
}


//Layouts
void addLayoutsMetadata(Metadata.DeployContainer mdContainer) {
    Set<String> layoutsToRetrieve = LAYOUT_TO_QUICK_ACTION.keySet().clone();
    layoutsToRetrieve.addAll(LAYOUT_TO_STANDARD_BUTTON.keySet());
    List<Metadata.Metadata> layouts = Metadata.Operations.retrieve(Metadata.MetadataType.Layout, 
                                                                                new List<String>(layoutsToRetrieve));
    for(Metadata.Metadata layoutMetadata : layouts) {
        Metadata.Layout layout = (Metadata.Layout)layoutMetadata;

        if (LAYOUT_TO_QUICK_ACTION.containsKey(layout.fullName)) {
            addQuickActionsToLayout(layout);
        }
        if (LAYOUT_TO_STANDARD_BUTTON.containsKey(layout.fullName)) {
            addExcludedButtonsToLayout(layout);
        }

        mdContainer.addMetadata(layout);
    }
}

void addQuickActionsToLayout(Metadata.Layout layout) {
    Set<String> quickActionsToAdd = LAYOUT_TO_QUICK_ACTION.get(layout.fullName).clone();
    //Check existing layout settings
    if(layout.quickActionList == null) {
        layout.quickActionList = new Metadata.QuickActionList();
        layout.quickActionList.quickActionListItems = new List<Metadata.QuickActionListItem>();
    } else if (layout.quickActionList.quickActionListItems == null) {
        layout.quickActionList.quickActionListItems = new List<Metadata.QuickActionListItem>();
    } else {
        //Exclude already added actions
        for(Metadata.QuickActionListItem action : layout.quickActionList.quickActionListItems) {
            quickActionsToAdd.remove(action.quickActionName);
        }
    }

    //Add other actions
    for(String quickActionToAdd : quickActionsToAdd){
        Metadata.QuickActionListItem quickAction = new Metadata.QuickActionListItem();
        quickAction.quickActionName = quickActionToAdd;
        layout.quickActionList.quickActionListItems.add(quickAction);
    }
}

void addExcludedButtonsToLayout(Metadata.Layout layout) {
    Set<String> removedButtons = new Set<String>(layout.excludeButtons);
    removedButtons.removeAll(LAYOUT_TO_STANDARD_BUTTON.get(layout.fullName));
    layout.excludeButtons = new List<String>(removedButtons);
}

//Permission Sets
void assignPermissionSetsToAdminAndSR() {
    //gather Permission Sets
    Set<String> permissionSetNames = new Set<String>();
    for (Set<String> psNames : USERS_PROFILE_TO_PERMISSION_SET.values()) {
        permissionSetNames.addAll(psNames);
    }
    Map<String, Id> permissionSetNameToId = new Map<String, Id>();
    for (PermissionSet ps : [SELECT Id, Name FROM PermissionSet WHERE Name IN :permissionSetNames]) {
        permissionSetNameToId.put(ps.Name, ps.Id);
    }

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
    Database.insert(assignments, false);
}

//Custom Permissions
void addCustomPermissionsToPermissionSets() {
    Map<String, Id> permissionSetNameToId = new Map<String, Id>();
    for (PermissionSet ps : [SELECT Id, Name FROM PermissionSet WHERE Name IN :PERMISSION_SET_TO_CUSTOM_PERMISSIONS.keySet()]) {
        permissionSetNameToId.put(ps.Name, ps.Id);
    }

    Set<String> customPermissionNames = new Set<String>();
    for (Set<String> cpNames : PERMISSION_SET_TO_CUSTOM_PERMISSIONS.values()) {
        customPermissionNames.addAll(cpNames);
    }
    Map<String, Id> customPermissionNameToId = new Map<String, Id>();
    for (CustomPermission ps : [SELECT Id, DeveloperName FROM CustomPermission WHERE DeveloperName IN :customPermissionNames]) {
        customPermissionNameToId.put(ps.DeveloperName, ps.Id);
    }

    List<SetupEntityAccess> accesses = new List<SetupEntityAccess>();
    for (String psName : PERMISSION_SET_TO_CUSTOM_PERMISSIONS.keySet()) {
        for (String cpName : PERMISSION_SET_TO_CUSTOM_PERMISSIONS.get(psName)) {
            accesses.add(
                    new SetupEntityAccess(
                            ParentId = permissionSetNameToId.get(psName),
                            SetupEntityId = customPermissionNameToId.get(cpName)
                    )
            );
        }
    }

    //Skip duplicates - already created accesses
    Database.insert(accesses, false);
}