report 87200 "wan Set Next No. Series Line"
{
    ApplicationArea = All;
    Caption = 'Set Next No. Series Line';
    ProcessingOnly = true;
    dataset
    {
        dataitem("No. Series Line"; "No. Series Line")
        {
            DataItemTableView = where("Starting No." = const(''));
            trigger OnPreDataItem()
            var
                ConfirmMsg: Label 'Do you want to set next line for %1 "%2"?';
            begin
                SetRange("Starting Date", StartingDate);
                if not confirm(ConfirmMsg, false, Count, TableCaption()) then
                    CurrReport.Quit();
            end;

            trigger OnAfterGetRecord()
            var
                FirstNoSeriesLine: Record "No. Series Line";
                String: Text;
                NextNoSerieLine: Record "No. Series Line";
            begin
                FirstNoSeriesLine.SetRange("Series Code", "Series Code");
                FirstNoSeriesLine.SetRange("Starting Date", 0D);
                FirstNoSeriesLine.SetFilter("Starting No.", '*__*');
                if FirstNoSeriesLine.FindFirst() then begin
                    NextNoSerieLine := "No. Series Line";
                    NextNoSerieLine."Starting Date" := NextStartingDate;
                    NextNoSerieLine."Line No." += 10000;
                    NextNoSerieLine.Insert(true);
                    String := FirstNoSeriesLine."Starting No.";
                    "Starting No." := String.Replace('__', ReplaceBy);
                    String := FirstNoSeriesLine."Ending No.";
                    "Ending No." := String.Replace('__', ReplaceBy);
                    Modify(true);
                    CountUpdate += 1;
                end;

            end;

            trigger OnPostDataItem()
            var
                DoneMsg: Label '%1 "%2" updated';
            begin
                Message(DoneMsg, CountUpdate, TableCaption);
            end;
        }
    }
    requestpage
    {
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
        CountUpdate: Integer;
}
