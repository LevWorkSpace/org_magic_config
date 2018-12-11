//Script is using MetadataConfiguration constants

assignPermissionSetsToAdminAndSR();

Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
addDBSchemaRecords(mdContainer);
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