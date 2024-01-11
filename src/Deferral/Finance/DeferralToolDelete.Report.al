report 87252 "wan Deferral Tool Delete"
{
    ProcessingOnly = true;
    dataset
    {
        dataitem("G/L Entry"; "G/L Entry")
        {
            RequestFilterFields = "G/L Account No.";
            trigger OnPreDataItem()
            begin
                if GetFilter("G/L Account No.").Substring(1, 2) <> '48' then
                    FieldError("G/L Account No.", 'Must be like 48%');
                if not Confirm('Process %1 record(s)?', false, Count) then
                    CurrReport.Quit();
            end;

            trigger OnAfterGetRecord()
            var
                DeferralLedgerEntry: Record "wan Deferral Ledger Entry";
            begin
                if DeferralLedgerEntry.Get("Entry No.") then
                    DeferralLedgerEntry.Delete()
            end;
        }
    }
}