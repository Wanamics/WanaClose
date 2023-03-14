/* Useless without the possibility to extend xmlport 12 "IC Outbox Imp/Exp"
tableextension 87274 "wan Handled IC Out. Sales Line" extends "Handled IC Outbox Sales Line"
{
    fields
    {
        field(87251; "wan Deferral Starting Date"; Date)
        {
            Caption = 'Starting Date';
            DataClassification = ToBeClassified;
            trigger OnValidate()
            begin
                wanCheckDeferralDates();
            end;
        }
        field(87252; "wan Deferral Ending Date"; Date)
        {
            Caption = 'Ending Date';
            DataClassification = ToBeClassified;
            trigger OnValidate()
            begin
                wanCheckDeferralDates();
            end;
        }
    }
    local procedure wanCheckDeferralDates();
    var
        DeferralDatesErr: label '%1 must be before %2';
    begin
        Rec.TestField("IC Partner Ref. Type", Rec."IC Partner Ref. Type"::"G/L Account");
        if ("wan Deferral Starting Date" > "wan Deferral Ending Date") and ("wan Deferral Ending Date" <> 0D) then
            Error(DeferralDatesErr, FieldCaption("wan Deferral Starting Date"), FieldCaption("wan Deferral Ending Date"));
    end;
}
*/