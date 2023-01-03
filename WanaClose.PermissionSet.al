permissionset 87200 "All"
{
    Access = Internal;
    Assignable = true;
    Caption = 'WanaClose', Locked = true;

    Permissions =
         codeunit "wan Prepaid Events" = X,
         page "wan Prepaid Ledger Entries" = X,
         report "wan Prepaid Ledger Entries" = X,
         report "wan Set Next No. Series Line" = X,
         report "wan Suggest Prepaid Entries" = X,
         report "wan Suggest Purch. Provisions" = X,
         report "wan Suggest Sales Provisions" = X,
         table "wan Prepaid Ledger Entry" = X,
         tabledata "wan Prepaid Ledger Entry" = RIMD;
}