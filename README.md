# org_magic_config
Automate Salesforce Orgs setup

Configuration is split on two steps:
- Execution of anonymous apex to updated Custom Metadata Records and Layouts(Apex Metadata API)
  https://developer.salesforce.com/docs/atlas.en-us.208.0.apexcode.meta/apexcode/apex_metadata_supported_types.htm
  MetadataConfiguration.cls - apex formatted constants - what should be configured by Apex Metadata API
- Execution of ant deploy to update unsupported(by Apex Metadata API) metadata(Profiles, etc)
  src_to_modify - source folder for ant deploy
  '[namespace]' expression will be replaced with namespace, specified in credentials/<org_name>.properties file 
