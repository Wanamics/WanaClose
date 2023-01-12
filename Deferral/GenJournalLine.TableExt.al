tableextension 87220 "wan Gen. Journal Line" extends "Gen. Journal Line"
{
    fields
    {
        field(87200; "wan Deferral Start Date"; Date)
        {
            Caption = 'Starting Date';
            DataClassification = ToBeClassified;

            trigger OnValidate()
            begin
                CheckDeferralDates();
            end;
        }
        field(87201; "wan Deferral End Date"; Date)
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
        if ("wan Deferral Start Date" > "wan Deferral End Date") and ("wan Deferral End Date" <> 0D) then
            Error(DeferralDatesErr, FieldCaption("wan Deferral Start Date"), FieldCaption("wan Deferral End Date"));
    end;
}
