/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/* vim: set tabstop=4 softtabstop=4 shiftwidth=4 expandtab :                  */
/*
 * common.vala
 *
 * Common methods for Tags application
 * Mostly static methods that need no instantiation
 * or scope yet to be defined
 *
 * José Miguel Fonte
 */

namespace Tags.Common {

    private static string generate_uuid () {
        string random_input = "%u-%u-%u".
            printf(GLib.Random.next_int (), GLib.Random.next_int (), GLib.Random.next_int ());
        var checksum = new Checksum (ChecksumType.SHA256);
        checksum.update (random_input.data, random_input.length);
        return checksum.get_string ();
    }

}
