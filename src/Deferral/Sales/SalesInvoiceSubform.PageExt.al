pageextension 87261 "Sales Invoice Subform" extends "Sales Invoice Subform"
{
    layout
    {
        addafter("Deferral Code")
        {
            field("wan Deferral Starting Date"; Rec."wan Deferral Starting Date")
            {
                ApplicationArea = All;
                Visible = false;
                Width = 9;
            }
            field("wan Deferral Ending Date"; Rec."wan Deferral Ending Date")
            {
                ApplicationArea = All;
                Visible = false;
                Width = 9;
            }
        }
    }
}
