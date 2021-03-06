//Constants to be used in metadata api script

//DbSchema records to Activate(DeveloperName)
final Set<String> DB_SCHEMA_TO_ACTIVATE = new Set<String>{
        'ContentTemplate_c',
        'EmailSettings_c',
        'EmailTemplate_c',
        'EmailTemplateVersion_c',
        'EmailTransaction_c',
        'Meeting_c',
        'MeetingBudget_c',
        'MeetingExpense_c',
        'MeetingExpenseAllocation_c',
        'MeetingLocation_c',
        'MeetingMember_c',
        'MeetingProduct_c',
        'MeetingsConfig_c',
        'MeetingTopic_c',
        'MeetingValidationSettings_c',
        'MeetingWorkFlowActionConfiguration_mdt',
        'MeetingWorkFlowConfiguration_mdt',
        'MeetingWorkFlowNodeConfiguration_mdt',
        'Opt_c',
        'OptDetail_c',
        'OptSettings_c',
        'Speaker_c',
        'TopicProduct_c',
        'TopicMaterial_c',
        'Location_c',
        'ExpenseType_c',
        'TOTRule_mdt',
        'TOTSettings_c',
        'TimeOffTerritorySlots_c',
        'DocumentTemplateVersion_c',
        'DocumentTemplate_c',
        'Document_c',
        'StandardTopic',
        'StandardTopicAssignment',
        'ContentDocument',
        'ContentDocumentLink',
        'ContentVersion',
        'QIDC_WC_Template_c',
        'InsightSettings_c',
        'Insight_c',
        'InsightTopic_c',
        'Vote_c'
};

//QuickAction custom metadata records to Activate('DeveloperName')
final Set<String> QUICK_ACTIONS_TO_ACTIVATE = new Set<String>{
        'MeetingsEmail',
        'SpeakersEmail'
};

//Trigger Handlers records to Activate('DeveloperName')
final Set<String> TRIGGER_HANDLERS_TO_ACTIVATE = new Set<String>{
        'AttachmentEmailTransactionHandler',
        'EmailQueueImmediate',
        'EmailQueueRecipient',
        'EmailQueueSender',
        'GeneralEventTOTValidationHandler',
        'TOTGeneralEventValidationHandler',
        'TOTOtherTOTValidationHandler',
        'MessageQueueTransactions',
        'VoteInsightRecalculation',
        'RecalculateLinkedInsightsHandler',
        'RecalculateInsightTagNamesHandler'
};

//Which quick actions should be added to which layout
final Map<String,Set<String>> LAYOUT_TO_QUICK_ACTION = new Map<String,Set<String>>{
        'PersonAccount-' + NAMESPACE + 'Business Contact Page Layout' => new Set<String>{
                'Account.'+ NAMESPACE + 'Email',
                'Account.'+ NAMESPACE + 'GenerateDocument',
                'Account.'+ NAMESPACE + 'ShareContent'
        },
        'Account-' + NAMESPACE + 'Institution Layout' => new Set<String>{
                'Account.'+ NAMESPACE + 'Email',
                'Account.'+ NAMESPACE + 'GenerateDocument',
                'Account.'+ NAMESPACE + 'ShareContent'
        },
        NAMESPACE + 'Meeting__c-'+ NAMESPACE + 'Meeting Layout' => new Set<String>{
                NAMESPACE + 'Meeting__c.' + NAMESPACE + 'LaunchPresentation'
        }
};

//Which lightning actions should be added to which layout
final Map<String,Set<String>> LAYOUT_TO_LIGHTNING_ACTION = new Map<String,Set<String>>{
        'PersonAccount-' + NAMESPACE + 'Business Contact Page Layout' => new Set<String>{
                'Account.'+ NAMESPACE + 'NewInsight'
        },
        'Account-' + NAMESPACE + 'Institution Layout' => new Set<String>{
                'Account.'+ NAMESPACE + 'NewInsight'
        },
        NAMESPACE + 'Meeting__c-'+ NAMESPACE + 'Meeting Layout' => new Set<String>{
                NAMESPACE + 'Meeting__c.' + NAMESPACE + 'NewInsight'
        }
};

//Which standard buttons should be added to which layout
final Map<String,Set<String>> LAYOUT_TO_STANDARD_BUTTON = new Map<String,Set<String>>{
        NAMESPACE + 'Meeting__c-' + NAMESPACE + 'Meeting Layout' => new Set<String>{
                'Edit'
        }
};