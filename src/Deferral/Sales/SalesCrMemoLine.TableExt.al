tableextension 87262 "Sales Cr. Memo Line" extends "Sales Cr.Memo Line"
{
    fields
    {
        field(87251; "wan Deferral Starting Date"; Date)
        {
            Caption = 'Starting Date';
            DataClassification = ToBeClassified;
        }
        field(87252; "wan Deferral Ending Date"; Date)
        {
            Caption = 'Ending Date';
            DataClassification = ToBeClassified;
        }
    }
}
