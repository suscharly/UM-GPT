@isTest
public class UMGPTPromptTemplateTest {

    @isTest
    static void testGeneratePromptSuccess() {
        // Create a sample Card__c record
        Card__c card = new Card__c(
            Name = 'Test Card',
            Summary__c = 'This is a test card for the GPT template.',
            Due_Date__c = Date.today().addDays(7)
        );
        insert card;

        // Create a valid U_M_GPT_Prompt__c record
        U_M_GPT_Prompt__c template = new U_M_GPT_Prompt__c(
            Object_API__c = 'Card__c',
            Fields__c = 'Summary__c,Due_Date__c',
            Name = 'Card Summary with DueDate',
            Status__c = 'Active',
            Visibility__c = 'Private',
            U_M_Unit__c = 'SFCOE',
            Prompt__c = 'Please give very short summary of the changes done. In past tense. Not more than 150 characters. Also add the {{{Due_Date__c}}}at the end of the summary \n\nDescription : {{{Summary__c}}}'
        );
        insert template;

        // Prepare request wrapper
        UMGPTPromptTemplateInvoke.RequestWrapper req = new UMGPTPromptTemplateInvoke.RequestWrapper();
        req.templateRecordId = template.Id;
        req.recordId = card.Id;

        // Call the invocable method
        List<UMGPTPromptTemplateInvoke.ResponseWrapper> results = 
            UMGPTPromptTemplateInvoke.generatePrompt(new List<UMGPTPromptTemplateInvoke.RequestWrapper>{ req });

        System.assertEquals(1, results.size());
        System.assert(results[0].prompt.contains('This is a test card for the GPT template.'));
        System.assert(results[0].prompt.contains(String.valueOf(card.Due_Date__c)));
        System.assertEquals('Test Card', results[0].recordName);
    }

    @isTest
    static void testMissingParameters() {
        UMGPTPromptTemplateInvoke.RequestWrapper req = new UMGPTPromptTemplateInvoke.RequestWrapper();
        req.templateRecordId = null;
        req.recordId = null;

        List<UMGPTPromptTemplateInvoke.ResponseWrapper> results = 
            UMGPTPromptTemplateInvoke.generatePrompt(new List<UMGPTPromptTemplateInvoke.RequestWrapper>{ req });

        
        System.debug(results[0].prompt);
        System.assertEquals('Error: Missing required parameters.', results[0].prompt);
    }
}
