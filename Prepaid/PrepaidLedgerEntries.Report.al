report 87221 "wan Prepaid Ledger Entries"
{
    ApplicationArea = All;
    Caption = 'Prepaid Entries';
    UsageCategory = ReportsAndAnalysis;
    DefaultLayout = RDLC;
    ExcelLayout = './Prepaid/PrepaidLedgerEntries.xlsx';
    RDLCLayout = './Prepaid/PrepaidLedgerEntries.rdl';
    dataset
    {
        dataitem(wanPrepaidLedgerEntry; "wan Prepaid Ledger Entry")
        {
            DataItemTableView = sorting("Gen. Posting Type", "Posting Date");
            RequestFilterFields = "Gen. Posting Type", "IC Partner Code";
            CalcFields = Amount;
            column(ReportCaption; CopyStr(CurrReport.ObjectId(true), 7)) { }
            column(PeriodText; StrSubstNo(PeriodLbl, PostingDate)) { }
            column(CompanyName; CompanyProperty.DisplayName()) { }
            column(GenPostingType; "Gen. Posting Type") { IncludeCaption = true; }
            column(PostingDate; "Posting Date") { IncludeCaption = true; }
            column(GLEntryNo; "G/L Entry No.") { IncludeCaption = true; }
            column(SourceNo; SourceAccount."No.") { }
            column(SourceNoCaption; SourceNoCaption) { }
            column(SourceName; SourceAccount."Name") { }
            column(SourceNameCaption; SourceNameCaption) { }
            column(AccountNo; GLENtry."G/L Account No.") { }
            column(AccountNoCaption; AccountNoCaption) { }
            column(Description; GLEntry.Description) { }
            column(DescriptionCaption; DescriptionCaption) { }
            column(Amount; Amount) { IncludeCaption = true; }
            column(StartingDate; "Starting Date") { IncludeCaption = true; }
            column(EndingDate; "Ending Date") { IncludeCaption = true; }
            column(OutstandingAmount; OutstandingAmount(PostingDate)) { }
            column(OutstandingAmountCaption; OutstandingAmountCaption) { }
            column(ICPartnerCode; "IC Partner Code") { IncludeCaption = true; }
            trigger OnPreDataItem()
            begin
                SetRange("Posting Date", 0D, PostingDate);
            end;

            trigger OnAfterGetRecord()
            begin
                if OutstandingAmount(PostingDate) = 0 then
                    CurrReport.Skip();
                GLEntry.Get("G/L Entry No.");
                SourceAccount := GetSourceAccount(GLEntry);
            end;
        }
    }
    requestpage
    {
        SaveValues = true;
        layout
        {
            area(content)
            {
                group(Options)
                {
                    field(PostingDate; PostingDate)
                    {
                        ApplicationArea = All;
                        Caption = 'Posting Date';
                    }
                }
            }
        }
    }
    var
        PostingDate: Date;
        GLEntry: Record "G/L Entry";
        SourceAccount: Record Vendor;
        OutstandingAmountCaption: Label 'Outstanding Amount';
        PeriodLbl: Label 'Period: %1';
        SourceNoCaption: Label 'Source No.';
        SourceNameCaption: Label 'Source Name';
        AccountNoCaption: Label 'Account No.';
        DescriptionCaption: Label 'Description';

    local procedure GetSourceAccount(pGLEntry: Record "G/L Entry") ReturnValue: Record Vendor
    var
        Customer: Record Customer;
    begin
        if pGLEntry."Source No." = '' then
            GetSourceEntry(pGLEntry);
        case pGLEntry."Source Type" of
            pGLEntry."Source Type"::Vendor:
                ReturnValue.Get(pGLEntry."Source No.");
            pGLEntry."Source Type"::Customer:
                if Customer.Get(pGLEntry."Source No.") then
                    ReturnValue.TransferFields(Customer);
            else
                Clear(ReturnValue);
        end;
    end;

    local procedure GetSourceEntry(var pGLEntry: Record "G/L Entry")
    begin
        pGLEntry.SetCurrentKey("Document No.", "Posting Date");
        pGLEntry.SetRange("Document No.", pGLEntry."Document No.");
        pGLEntry.SetRange("Posting Date", pGLEntry."Posting Date");
        pGLEntry.SetFilter("Source Type", '%1|%2', pGLEntry."Source Type"::Vendor, pGLEntry."Source Type"::Customer);
        if pGLEntry.FindFirst() then;
    end;
}
