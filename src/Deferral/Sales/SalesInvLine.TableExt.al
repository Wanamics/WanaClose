tableextension 87261 "Sales Invoice Line" extends "Sales Invoice Line"
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