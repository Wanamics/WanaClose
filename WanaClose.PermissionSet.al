permissionset 87250 "wan WanaClose"
{
    Access = Internal;
    Assignable = true;
    Caption = 'WanaClose', Locked = true;

    Permissions =
         codeunit "wan Deferral Events" = X,
         codeunit "wan Deferral Purchase Events" = X,
         codeunit "wan Deferral Sales Events" = X,
         page "wan Deferral Ledger Entries" = X,
         report "wan Deferral Ledger Entries" = X,
         report "wan Suggest Deferral Entries" = X,
         report "wan Suggest Purch. Provisions" = X,
         report "wan Suggest Sales Provisions" = X,
         table "wan Deferral Ledger Entry" = X,
         tabledata "wan Deferral Ledger Entry" = RIMD;
}