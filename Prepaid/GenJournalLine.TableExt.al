tableextension 87220 "wan Gen. Journal Line" extends "Gen. Journal Line"
{
    fields
    {
        field(87200; "wan Starting Date"; Date)
        {
            Caption = 'Starting Date';
            DataClassification = ToBeClassified;

            trigger OnValidate()
            begin
                CheckPrepaidDates();
            end;
        }
        field(87201; "wan Ending Date"; Date)
        {
            Caption = 'Ending Date';
            trigger OnValidate()
            begin
                CheckPrepaidDates();
            end;
        }
        field(87202; "wan Prepaid Entry No."; Integer)
        {
            Caption = 'Prepaid Entry No.';
            TableRelation = "G/L Entry";
        }
    }
    local procedure CheckPrepaidDates();
    var
        PrepaidDatesErr: label '%1 must be before %2';
    begin
        if ("wan Starting Date" > "wan Ending Date") and ("wan Ending Date" <> 0D) then
            Error(PrepaidDatesErr, FieldCaption("wan Starting Date"), FieldCaption("wan Ending Date"));
    end;
}
