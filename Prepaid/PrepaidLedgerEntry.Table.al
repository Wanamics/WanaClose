table 87220 "wan Prepaid Ledger Entry"
{
    Caption = 'Prepaid Ledger Entry';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "G/L Entry No."; Integer)
        {
            Caption = 'G/L Entry No.';
            DataClassification = ToBeClassified;
            TableRelation = "G/L Entry";
        }
        field(4; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(48; "Gen. Posting Type"; Enum "General Posting Type")
        {
            Caption = 'Gen. Posting Type';
        }
        field(72; "IC Partner Code"; Code[20])
        {
            Caption = 'IC Partner Code';
            TableRelation = "IC Partner";
        }
        field(89220; "Prepaid G/L Entry No."; Integer)
        {
            Caption = 'Prepaid G/L Entry No.';
            DataClassification = ToBeClassified;
            TableRelation = "G/L Entry";
        }
        field(89221; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
            DataClassification = ToBeClassified;
            NotBlank = true;
            trigger OnValidate()
            begin
                CheckPrepaidDates()
            end;
        }
        field(89222; "Ending Date"; Date)
        {
            Caption = 'End Date';
            DataClassification = ToBeClassified;
            NotBlank = true;
            trigger OnValidate()
            begin
                CheckPrepaidDates()
            end;
        }
        field(89223; Amount; Decimal)
        {
            Caption = 'Amount';
            FieldClass = FlowField;
            CalcFormula = lookup("G/L Entry".Amount where("Entry No." = field("G/L Entry No.")));
            Editable = false;
        }
    }
    keys
    {
        key(PK; "G/L Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Prepaid G/L Entry No.")
        {
        }
        key(Key3; "Gen. Posting Type", "Posting Date", "IC Partner Code")
        {

        }
    }
    procedure OutstandingAmount(pPostingDate: Date) ReturnValue: Decimal
    var
        lRec: Record "wan Prepaid Ledger Entry";
    begin
        lRec.SetAutoCalcFields(Amount);
        lRec.SetRange("Prepaid G/L Entry No.", "G/L Entry No.");
        lRec.SetRange("Posting Date", 0D, pPostingDate);
        if lRec.FindSet() then
            repeat
                ReturnValue += lRec.Amount;
            until lRec.Next() = 0;
    end;

    local procedure CheckPrepaidDates();
    var
        PrepaidDatesErr: label '%1 must be before %2';
    begin
        Rec.TestField("Gen. Posting Type");
        if ("Starting Date" > "Ending Date") and ("Ending Date" <> 0D) then
            Error(PrepaidDatesErr, FieldCaption("Starting Date"), FieldCaption("Ending Date"));
    end;
}