/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/* vim: set tabstop=4 softtabstop=4 shiftwidth=4 expandtab :                  */
/*
 * main.vala
 *
 * Application entry point 
 *
 * José Miguel Fonte
 */

int main (string[] args) {
    /* i18n setup */
    Intl.setlocale (LocaleCategory.ALL, "");
    Intl.bindtextdomain (Constants.GETTEXT_PACKAGE, Constants.LOCALEDIR);
    Intl.bind_textdomain_codeset (Constants.GETTEXT_PACKAGE, "UTF-8");
    Intl.textdomain (Constants.GETTEXT_PACKAGE);

    return new Tags.Application ().run (args);
}
