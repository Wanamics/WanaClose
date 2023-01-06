page 87220 "wan Prepaid Ledger Entries"
{
    ApplicationArea = All;
    Caption = 'Prepaid Entries';
    PageType = List;
    SourceTable = "wan Prepaid Ledger Entry";
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("G/L Entry No."; Rec."G/L Entry No.")
                {
                    ToolTip = 'Specifies the value of the G/L Entry No. field.';
                    Visible = false;
                    Editable = false;
                }
                field("Gen. Posting Type"; Rec."Gen. Posting Type")
                {
                    ToolTip = 'Specifies the value of the Gen. Posting Type field.';
                    Editable = false;
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ToolTip = 'Specifies the value of the Posting Date field.';
                    Editable = false;
                }
                field(DocumentNo; GLEntry."Document No.")
                {
                    Caption = 'Document No.';
                    Editable = false;
                }
                field(ExternalDocumentNo; GLEntry."External Document No.")
                {
                    Caption = 'External Document No.';
                    Editable = false;
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ToolTip = 'Specifies the value of the Starting Date field.';
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ToolTip = 'Specifies the value of the End Date field.';
                }
                field("Prepaid G/L Entry No."; Rec."Prepaid G/L Entry No.")
                {
                    ToolTip = 'Specifies the value of the Prepaid G/L Entry No. field.';
                    Visible = false;
                    Editable = false;
                }
                field(Amount; Rec.Amount)
                {
                    ToolTip = 'Specifies the value of the Amount field.';
                    Editable = false;
                }
                field(Description; GLEntry.Description)
                {
                    Caption = 'Description';
                    Editable = false;
                }
                field(SourceNo; GLEntry."Source No.")
                {
                    Caption = 'Source No.';
                    Editable = false;
                }
                field(SourceName; SourceName)
                {
                    Caption = 'Source Name';
                    Editable = false;
                }
            }
        }
    }
    trigger OnAfterGetRecord()
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        Employee: Record Employee;
    begin
        GLEntry.Get(Rec."G/L Entry No.");
        SourceName := '';
        case GLEntry."Bal. Account Type" of
            GLEntry."Bal. Account Type"::Vendor:
                if Vendor.Get(GLEntry."Source No.") then
                    SourceName := Vendor.Name;
            GLEntry."Bal. Account Type"::Customer:
                if Customer.Get(GLEntry."Source No.") then
                    SourceName := Customer.Name;
            GLEntry."Bal. Account Type"::Employee:
                if Employee.Get(GLEntry."Source No.") then
                    SourceName := Employee.FullName;
        end;
    end;

    var
        GLEntry: Record "G/L Entry";
        SourceName: Text;
}
