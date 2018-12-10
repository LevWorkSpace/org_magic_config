//Script is using MetadataConfiguration constants

assignPermissionSetsToAdminAndSR();

Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
addDBSchemaRecords(mdContainer);
addTriggerHandlerRecords(mdContainer);
addCustomMetadataQuickActionRecords(mdContainer);
addLayoutQuickActionsMetadata(mdContainer);
Metadata.Operations.enqueueDeployment(mdContainer, null);


//Service methods
void addDBSchemaRecords(Metadata.DeployContainer mdContainer) { 
    for(sObject dbSchemaRecord : queryMetadata('DbSchema__mdt', DB_SCHEMA_TO_ACTIVATE)) {
        mdContainer.addMetadata(
            buildActiveMetadataRecord(dbSchemaRecord)
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

void addLayoutQuickActionsMetadata(Metadata.DeployContainer mdContainer) {   
    List<Metadata.Metadata> layouts = Metadata.Operations.retrieve(Metadata.MetadataType.Layout, new List<String>(LAYOUT_TO_QUICK_ACTION.keySet()));
    
    for(Metadata.Metadata layout : layouts){
        Metadata.Layout la = (Metadata.Layout)layout;
        for(String quickActionName : LAYOUT_TO_QUICK_ACTION.get(la.fullName)){
            Metadata.QuickActionListItem quickAction = new Metadata.QuickActionListItem();
            quickAction.quickActionName = quickActionName;
            if(la.quickActionList != null && la.quickActionList.quickActionListItems != null){
                Boolean doesAlreadyExist = false;
                for(Metadata.QuickActionListItem action : la.quickActionList.quickActionListItems){
                    if(action.quickActionName == quickActionName){
                        doesAlreadyExist = true;
                        break;
                    }
                }
                if(!doesAlreadyExist){
                    la.quickActionList.quickActionListItems.add(quickAction);
                }
            } else {
                la.quickActionList = new Metadata.QuickActionList();
                la.quickActionList.quickActionListItems = new List<Metadata.QuickActionListItem>();
                la.quickActionList.quickActionListItems.add(quickAction);
            }
        }
        mdContainer.addMetadata(la);
    }
}

void assignPermissionSetsToAdminAndSR() {
    List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();
    for (String profile : USERS_PROFILE_TO_PERMISSION_SET.keySet()) {
        assignments.addAll(createPermissionSetAssignments(profile, USERS_PROFILE_TO_PERMISSION_SET.get(profile)));
    }

    //Skip duplicates - already created assignments
    Database.insert(assignments, false);
}

List<PermissionSetAssignment> createPermissionSetAssignments(String profileName, Set<String> permissionSetNames) {
    List<PermissionSet> permissionSets = [SELECT Id FROM PermissionSet WHERE Name IN :permissionSetNames];
    List<User> users = [SELECT Id FROM User WHERE Profile.Name = :profileName];

    List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();

    for (User user : users) {
        for (PermissionSet permissionSet : permissionSets) {
            assignments.add(new PermissionSetAssignment(
                    AssigneeId = user.Id,
                    PermissionSetId = permissionSet.Id
            ));
        }
    }

    return assignments;
}