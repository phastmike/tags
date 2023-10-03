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
	var app = new Tags.Application ();
	return app.run (args);
}
