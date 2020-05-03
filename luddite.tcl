# luddite.tcl --
#
#    This file implements the Tcl code for simple Common Gateway Interface
#    (RFC 3875 [0]) and HTTP (RFC 7231 [1]) interaction. The library's
#    objective is simplicity, not completeness.
#
# Copyright (c) 2020 Thomas Lee Culverwell
#
# See the LICENSE file for information on usage and redistribution of this
# file, and for a DISCLAIMER OF ALL WARRANTIES.
package require Tcl 8.6
package provide luddite 0.0.1
namespace eval luddite {
  set description "Framebreaking with Common Gateway Interface applications"
  namespace export header GET POST
}
# luddite::header --
#
#     Declare an HTTP header with appropriate MIME type (RFC 2045 [2]).
#
# Arguments:
#     mimetype    MIME type string (eg. {application/xml})
#
# Results:
#     Valid HTTP header string (including newlines)
proc header mimetype {
    return "Content-Type: $mimetype \n\n"
}
# luddite::URLdecode --
#
#     Convert an URL-encoded string into its original unencoded form.
#
# Arguments:
#     str    An URL-encoded string (RFC 3986 [3]).
#            Note: procedure adapted from Rosetta Code [4].
#
# Results:
#     The unencoded original text
proc URLdecode {str} {
    set specialMap {{[{ }%5B{ }]} {%5D}}
    set seqRE {%([0-9a-fA-F]{2})}
    set replacement {[format {%c} [scan "\1" {%2x}]]}
    set modStr [regsub -all $seqRE [string map $specialMap $str] $replacement]
    return [encoding convertfrom utf-8 [subst -nobackslash -novariable $modStr]]
}
# luddite::Parse --
#
#     Break up an HTTP request into logical chunks.
#
# Arguments:
#     query    A string representing the HTTP POST or GET request:
#                  * GET requests give us a $QUERY_STRING
#                  * POST requests can be parsed from the $CONTENT_LENGTH
#
#              A query string is composed of a series of field-value pairs:
#                  * In each pair, keys and values are seperated by `=`
#                  * The series of pairs is seperated by `&` or `;`.
#                  * Query strings will always begin after a `?` in an URL
# Results:
#     A list of ordered pairs where the X is the key and Y is the value
#     (eg. {{name alice} {name bob}}).
proc Parse query {
    return [lmap pairs [split [URLdecode $query] {&;}] {split $pairs =}]
}
# luddite::GET / luddite::POST --
#
#     Contents of GET and POST requests, parsed and decoded.
#
# From the Tcler's Wiki [4]:
#
# > The env array is one of the magic names created by Tcl to reflect the
# > value of the invoker's environment; that is to say, when one starts
# > Tcl, what one does is make a request to the operating system to start
# > a new process. If the process is being started directly, that process
# > is typically given a set of variables called environment variables
# > which reflect certain default values. When Tcl starts, it creates the
# > env array and reads the environment. Each environment variable becomes
# > a key in this array whose value is the value of the environment
# > variable.
#
# The data of a GET or POST request is relatively unstructured,
# so we represent them as lists of paris, eg.:
#
#     {{name alice} {name bob}}
#
global env
set GET  {}
set POST {}
if [info exists env(QUERY_STRING)] {
    append GET [Parse $env(QUERY_STRING)]
}
if [info exists env(CONTENT_LENGTH)] {
    append POST [Parse [read stdin $env(CONTENT_LENGTH)]]
}
# References
#
# [0]: https://tools.ietf.org/html/rfc3875
# [1]: https://tools.ietf.org/html/rfc7231
# [2]: https://tools.ietf.org/html/rfc2045
# [3]: https://tools.ietf.org/html/rfc3986
# [4]: https://www.rosettacode.org/wiki/URL_decoding#Tcl
# [5]: https://wiki.tcl-lang.org/page/env
