
/***************************
 * Name: UMGPTPromptTemplateInvoke
 * Created by Sushin Gigy {DateCreated [08/12/2025]} 
----------------------------------------------------------------------------------
 * Purpose: 
** Provides Flow-invocable wrapper for U-M GPT prompt template processing functionality
** Enables Salesforce Flows and Process Builder to generate AI prompts using dynamic templates
** Acts as integration layer between declarative automation tools and prompt processing service
 * Methods: 
** generatePrompt() - Invocable method that processes multiple prompt template requests from Flow/Process Builder
----------------------------------------------------------------------------------
* History:
* VERSION       DEVELOPER NAME      DATE        DETAIL/FEATURES
* 1.0           Sushin Gigy        08/13/2025      Initial implementation of Flow-invocable prompt generation
* 
*/




public with sharing class UMGPTPromptTemplateInvoke {
	/**
     * @description Main invocable method that generates AI prompts from templates for use in Salesforce Flows
     * This method:
     * 1. Accepts a list of request objects containing template and record IDs
     * 2. Validates required parameters for each request
     * 3. Calls the core processing service for each valid request
     * 4. Returns processed results in Flow-compatible format
     * 
     * Benefits for Flow builders:
     * - Batch processing support (handles multiple requests in one transaction)
     * - Built-in error handling with descriptive messages
     * - Standardized input/output structure for easy Flow integration
     * 
     * @param requests List of RequestWrapper objects containing template and record ID pairs
     * @return List<ResponseWrapper> containing processed prompts and record names for each request
     */
    
    @InvocableMethod(label='Generate GPT Prompt' description='Replaces placeholders in the GPT prompt template with record field values.')
    public static List<ResponseWrapper> generatePrompt(List<RequestWrapper> requests) {
 
        // Process each request individually to handle mixed success/failure scenarios
        // This approach ensures that one failed request doesn't prevent others from processing
        List<ResponseWrapper> responses = new List<ResponseWrapper>();
        
        for (RequestWrapper req : requests) {
            ResponseWrapper response = new ResponseWrapper();
            
            // Step 1: Validate required input parameters
            // Both template ID and record ID are necessary for prompt generation
            if (req.templateRecordId == null || req.recordId == null) {
                // Create error response for invalid input - Flow can handle this gracefully
                response.recordName = '';
                response.prompt = 'Error: Missing required parameters.';
                responses.add(response);
                continue;// Skip to next request rather than failing entire batch
            }
            
            // Step 2: Call the core processing service with validated parameters
            // UMGPTPromptTemplateProcess handles all the complex logic for:
            // - Template retrieval and validation
            // - Dynamic record querying
            // - Placeholder replacement
            // - HTML sanitization
            UMGPTPromptTemplateProcess.Result result = UMGPTPromptTemplateProcess.processTemplate(req.templateRecordId, req.recordId);

            // Step 3: Map service results to Flow-compatible response format
            response.recordName = result.recordName;
            response.prompt = result.prompt;
            
            // Add processed response to results collection
            responses.add(response);
        }
        
        return responses;
    }

    /**
     * @description Input wrapper class for Flow invocable method parameters
     * Defines the required input structure that Flow builders need to provide
     * Each instance represents one prompt generation request
     */
    
    public class RequestWrapper {
        /**
         * @description ID of the U_M_GPT_Prompt__c template record to use for generation
         * This template contains the object API name, field list, and prompt structure
         */
        @InvocableVariable(label='Template Record ID' required=true)
        public Id templateRecordId;

        /**
         * @description ID of the target record whose field values will populate the template
         * This can be any Salesforce record type (Contact, Account, Case, etc.)
         */
        @InvocableVariable(label='Target Record ID' required=true)
        public Id recordId;
    }

    /**
     * @description Output wrapper class for Flow invocable method results
     * Provides structured response data that Flow builders can use in subsequent elements
     * Each instance contains the results of one prompt generation request
     */
    public class ResponseWrapper {
        /**
         * @description Name of the record used to populate the template
         * Useful for Flow builders to display context or create audit trails
         * Will be empty string if processing failed
         */
        @InvocableVariable(label='Record Name')
        public String recordName;

        /**
         * @description Final processed prompt with placeholders replaced by actual field values
         * This is the primary output that can be used for AI interactions
         * Will contain error message if processing failed
         */
        @InvocableVariable(label='Processed Prompt')
        public String prompt;

    }
}
