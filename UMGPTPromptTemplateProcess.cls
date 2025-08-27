/***************************
 * Name: UMGPTPromptTemplateProcess
 * Created by Sushin Gigy {DateCreated 08/13/2025} 
----------------------------------------------------------------------------------
 * Purpose: 
** Processes U-M GPT prompt templates by dynamically fetching record data and replacing placeholders
** Enables dynamic prompt generation for AI interactions using configurable templates
 * Methods: 
** processTemplate() - Main method that processes a template record and replaces placeholders with actual record data
** replacePlaceholders() - Private helper method to replace template placeholders with field values
** sanitizeHtml() - Private helper method to remove HTML content for security and clean output
----------------------------------------------------------------------------------
* History:
* VERSION       DEVELOPER NAME      DATE        DETAIL/FEATURES
* 1.0          Sushin Gigy       08/13/2025     Initial implementation of dynamic prompt template processing
* 
*/



public with sharing class UMGPTPromptTemplateProcess {
    /**
     * @description Inner class to structure the return data from template processing
     * Contains the processed prompt and the record name for reference
     */
    public class Result {
        public String recordName; // Name of the record used to populate the template
        public String prompt; // Final processed prompt with placeholders replaced
    }

    
    /**
     * @description Main method to process a prompt template with data from a specific record
     * This method:
     * 1. Fetches the template configuration record
     * 2. Validates required template fields are populated
     * 3. Dynamically queries the target record based on template configuration
     * 4. Replaces placeholders in the template with actual field values
     * 5. Sanitizes the output for security
     * 
     * @param templateRecordId Id of the U_M_GPT_Prompt__c template record to use
     * @param recordId Id of the target record whose data will populate the template
     * @return Result object containing the processed prompt and record name
     */
    public static Result processTemplate(Id templateRecordId, Id recordId) {
        Result result = new Result();
        
        // Step 1: Fetch the template record containing configuration details
        // The template defines which object to query, which fields to include, and the prompt structure
        U_M_GPT_Prompt__c template = [
            SELECT Object_API__c, Fields__c, Prompt__c 
            FROM U_M_GPT_Prompt__c 
            WHERE Id = :templateRecordId 
            LIMIT 1
        ];
        // Step 2: Validate that all required template fields are populated
        // Without these fields, we cannot process the template successfully
        if (template.Object_API__c == null || template.Fields__c == null || template.Prompt__c == null) {
            result.prompt = 'Error: Template is missing required fields.';
            result.recordName='';
            return result;
        }
        
        // Step 3: Build and execute dynamic query for the target record
        // Parse the comma-separated field list and add 'Name' field for record identification
        String objectName = template.Object_API__c;
        List<String> fieldNames = template.Fields__c.split(',');
        fieldNames.add('Name');// Always include Name field for record identification

        // Construct dynamic SOQL query based on template configuration
        String query = 'SELECT ' + String.join(fieldNames, ',') + ' FROM ' + objectName + ' WHERE Id = :recordId';
        
        SObject targetRecord;
        try {
            // Execute the dynamic query to fetch the target record
            targetRecord = Database.query(query);
        } catch (Exception e) {
            
            // Handle cases where the query fails (invalid object, fields, or record not found)
            result.prompt = 'Error: Unable to retrieve target record. ' + e.getMessage();
            result.recordName = '';
            return result;
        }

        // Step 4: Extract the record name for reference
        result.recordName = String.valueOf(targetRecord.get('Name'));
        
        // Step 5: Replace template placeholders with actual field values from the target record
        String processedPrompt = replacePlaceholders(template.Prompt__c, fieldNames, targetRecord);
        
       // Step 6: Clean the output by removing HTML content for security and readability
        processedPrompt = sanitizeHtml(processedPrompt);

        // Step 7: Populate final result and return
        result.prompt = processedPrompt;
        result.recordName = String.valueOf(targetRecord.get('Name'));
        
        return result;
    }
      /**
     * @description Private helper method to replace placeholders in template with actual field values
     * Searches for placeholders in format {{{fieldName}}} and replaces them with corresponding field values
     * 
     * @param template The prompt template string containing placeholders
     * @param fields List of field names to process for replacement
     * @param record The SObject record containing the field values
     * @return String with all placeholders replaced with actual field values
     */
    private static String replacePlaceholders(String template, List<String> fields, SObject record) {
        // Loop through each field and replace its placeholder with the actual value
        for (String field : fields) {
            field = field.trim();// Remove any whitespace from field name

            // Skip empty field names to avoid errors
            if (String.isEmpty(field)) continue;
            
            // Create placeholder pattern: {{{fieldName}}}
            String placeholder = '{{{' + field + '}}}';
            Object value = record.get(field);
            String fieldValue = value != null ? String.valueOf(value) : '';
            
            
            // Get the field value from the record, handling null values gracefully
            template = template.replace(placeholder, fieldValue);
        }
        return template;
    }

      /**
     * @description Private helper method to sanitize HTML content from the processed prompt
     * Removes HTML tags and potentially dangerous script content for security
     * This ensures the output is clean text suitable for AI prompt processing
     * 
     * @param input The string to sanitize
     * @return String with HTML content removed
     */
    private static String sanitizeHtml(String input) {
        // Handle null input gracefully
        if (input == null) return '';
        
        // Remove all HTML tags using regex pattern
        // Pattern <[^>]*> matches any text between < and >
        input = input.replaceAll('<[^>]*>', '');
        
        // Additional security: Remove script tags and their content
        // This prevents any JavaScript execution if HTML somehow gets throughy
        input = input.replaceAll('(?i)<script.*?>.*?</script>', '');

        // Return cleaned string with leading/trailing whitespace removed
        return input.trim();
    }
    
}
