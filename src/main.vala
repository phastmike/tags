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
    /* I18N setup */
    Intl.setlocale (LocaleCategory.ALL, "");
    Intl.bindtextdomain (Constants.GETTEXT_PACKAGE, Constants.LOCALEDIR);
    Intl.bind_textdomain_codeset (Constants.GETTEXT_PACKAGE, "UTF-8");
    Intl.textdomain (Constants.GETTEXT_PACKAGE);

    //stdout.printf ("[i18n] gettext domain: %s\n", Constants.GETTEXT_PACKAGE);
    //stdout.printf ("[i18n] gettext locale dir: %s\n", Constants.LOCALEDIR);


    /* Start the Application */
	var app = new Tags.Application ();
	return app.run (args);
}
