pageextension 87260 "wan Sales Journal" extends "Sales Journal"
{
    layout
    {
        addbefore("Bal. Account Type")
        {
            field("Starting Date"; Rec."wan Deferral Starting Date")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Starting Date field.';
                Width = 9;
            }
            field("Ending Date"; Rec."wan Deferral Ending Date")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Ending Date field.';
                Width = 9;
            }
        }
    }
}