report 87200 "wan Set Next No. Series Line"
{
    ApplicationArea = All;
    Caption = 'Set Next No. Series Line';
    ProcessingOnly = true;
    dataset
    {
        dataitem("No. Series Line"; "No. Series Line")
        {
            DataItemTableView = where("Starting No." = filter('*__*'), "Starting Date" = const());
            trigger OnPreDataItem()
            var
                ReplaceByIsRequiredErr: Label 'ReplaceBy is required';
                ConfirmMsg: Label 'Do you want to set next line for %1 "%2"?';
            begin
                if ReplaceBy = '' then
                    Error(ReplaceByIsRequiredErr);
                if not confirm(ConfirmMsg, false, Count, TableCaption()) then
                    CurrReport.Quit();
            end;

            trigger OnAfterGetRecord()
            var
                StringNo: Text;
                NoSeriesLine: Record "No. Series Line";
            begin
                SetNoSeriesLine(NoSeriesLine, "No. Series Line", StartingDate);
                StringNo := "Starting No.";
                if NoSeriesLine."Starting No." = '' then
                    NoSeriesLine.Validate("Starting No.", StringNo.Replace('__', ReplaceBy));
                StringNo := "Ending No.";
                if NoSeriesLine."Ending No." = '' then
                    NoSeriesLine.Validate("Ending No.", StringNo.Replace('__', ReplaceBy));
                NoSeriesLine.Modify(true);
                SetNoSeriesLine(NoSeriesLine, "No. Series Line", NextStartingDate);
                CountProcessed += 1;
            end;


            trigger OnPostDataItem()
            var
                DoneMsg: Label '%1 "%2" processed';
            begin
                Message(DoneMsg, CountProcessed, TableCaption);
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
                    field(StartingDate; StartingDate)
                    {
                        Caption = 'Starting Date';
                        ApplicationArea = All;
                    }
                    field(ReplaceBy; ReplaceBy)
                    {
                        Caption = 'Replace __ by';
                        ApplicationArea = All;
                        trigger OnValidate()
                        var
                            LenErr: Label 'Must be 2 character long';
                        begin
                            if StrLen(ReplaceBy) <> 2 then
                                Error(LenErr);
                        end;
                    }
                    field(NextStartingDate; NextStartingDate)
                    {
                        Caption = 'Next Starting Date';
                        ApplicationArea = All;
                        trigger OnValidate()
                        var
                            MustBeGTStaringDateErr: Label 'Must be greater then starting Date';
                        begin
                            if NextStartingDate <= StartingDate then
                                Error(MustBeGTStaringDateErr);
                        end;
                    }
                }
            }
        }
    }
    var
        StartingDate: Date;
        NextStartingDate: Date;
        ReplaceBy: Code[2];
        CountProcessed: Integer;

    local procedure SetNoSeriesLine(var pToNoSerieLine: Record "No. Series Line"; pFromNoSeriesLine: Record "No. Series Line"; pStartingDate: Date)
    begin
        pToNoSerieLine.SetRange("Series Code", pFromNoSeriesLine."Series Code");
        pToNoSerieLine.SetRange("Starting Date", pStartingDate);
        if not pToNoSerieLine.FindFirst() then begin
            pToNoSerieLine.SetRange("Starting Date");
            if pToNoSerieLine.FindLast() then;
            pToNoSerieLine.TransferFields(pFromNoSeriesLine, false);
            pToNoSerieLine."Line No." += 10000;
            pToNoSerieLine."Starting Date" := pStartingDate;
            pToNoSerieLine.Validate("Starting Date", pStartingDate);
            pToNoSerieLine.Validate("Starting No.", '');
            pToNoSerieLine.Validate("Ending No.", '');
            pToNoSerieLine.Insert(true);
        end;
    end;
}
