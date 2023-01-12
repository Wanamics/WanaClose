tableextension 87220 "wan Gen. Journal Line" extends "Gen. Journal Line"
{
    fields
    {
        field(87200; "wan Deferral Starting Date"; Date)
        {
            Caption = 'Starting Date';
            DataClassification = ToBeClassified;

            trigger OnValidate()
            begin
                CheckDeferralDates();
            end;
        }
        field(87201; "wan Deferral Ending Date"; Date)
        {
            Caption = 'Ending Date';
            trigger OnValidate()
            begin
                CheckDeferralDates();
            end;
        }
        field(87202; "wan Deferral Entry No."; Integer)
        {
            Caption = 'Deferral Entry No.';
            TableRelation = "G/L Entry";
        }
    }
    local procedure CheckDeferralDates();
    var
        DeferralDatesErr: label '%1 must be before %2';
    begin
        if ("wan Deferral Starting Date" > "wan Deferral Ending Date") and ("wan Deferral Ending Date" <> 0D) then
            Error(DeferralDatesErr, FieldCaption("wan Deferral Starting Date"), FieldCaption("wan Deferral Ending Date"));
    end;
}
