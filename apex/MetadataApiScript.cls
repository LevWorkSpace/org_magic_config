//Script is using MetadataConfiguration constants
Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
activateMetadataRecords('DbSchema__mdt', DB_SCHEMA_TO_ACTIVATE, mdContainer);
activateMetadataRecords('TriggerHandler__mdt', TRIGGER_HANDLERS_TO_ACTIVATE, mdContainer);
activateMetadataRecords('QuickAction__mdt', QUICK_ACTIONS_TO_ACTIVATE, mdContainer);
addLayoutsMetadata(mdContainer);
Metadata.Operations.enqueueDeployment(mdContainer, null);

//Service methods
//Custom Metadata
void activateMetadataRecords(String metadataName, Set<String> recordsToActivate, Metadata.DeployContainer mdContainer) {
    for(sObject dbSchemaRecord : queryMetadata(metadataName, recordsToActivate)) {
        mdContainer.addMetadata(
                buildActiveMetadataRecord(dbSchemaRecord)
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
    layoutsToRetrieve.addAll(LAYOUT_TO_LIGHTNING_ACTION.keySet());
    layoutsToRetrieve.addAll(LAYOUT_TO_STANDARD_BUTTON.keySet());
    List<Metadata.Metadata> layouts = Metadata.Operations.retrieve(Metadata.MetadataType.Layout,
            new List<String>(layoutsToRetrieve));
    for(Metadata.Metadata layoutMetadata : layouts) {
        Metadata.Layout layout = (Metadata.Layout)layoutMetadata;

        if (LAYOUT_TO_QUICK_ACTION.containsKey(layout.fullName)) {
            addQuickActionsToLayout(layout);
        }
        if (LAYOUT_TO_LIGHTNING_ACTION.containsKey(layout.fullName)) {
            addLightningActionsToLayout(layout);
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
void addLightningActionsToLayout(Metadata.Layout layout) {
    Set<String> lightningActionsToAdd = LAYOUT_TO_LIGHTNING_ACTION.get(layout.fullName).clone();
    //Check existing layout settings
    if(layout.platformActionList == null) {
        layout.platformActionList = new Metadata.PlatformActionList();
        layout.platformActionList.platformActionListItems = new List<Metadata.PlatformActionListItem>();
    } else if (layout.platformActionList.platformActionListItems == null) {
        layout.platformActionList.platformActionListItems = new List<Metadata.PlatformActionListItem>();
    } else {
        //Exclude already added actions
        for(Metadata.PlatformActionListItem action : layout.platformActionList.platformActionListItems) {
            lightningActionsToAdd.remove(action.actionName);
        }
    }
    //Add other actions
    Integer sortOrder = layout.platformActionList.platformActionListItems.size();
    for(String lightningActionToAdd : lightningActionsToAdd){
        Metadata.PlatformActionListItem lightningAction = new Metadata.PlatformActionListItem();
        lightningAction.actionName = lightningActionToAdd;
        lightningAction.actionType = Metadata.PlatformActionTypeEnum.QuickAction;
        lightningAction.sortOrder = sortOrder;
        layout.platformActionList.platformActionListItems.add(lightningAction);
        sortOrder++;
    }
}

void addExcludedButtonsToLayout(Metadata.Layout layout) {
    Set<String> removedButtons = new Set<String>(layout.excludeButtons);
    removedButtons.removeAll(LAYOUT_TO_STANDARD_BUTTON.get(layout.fullName));
    layout.excludeButtons = new List<String>(removedButtons);
}