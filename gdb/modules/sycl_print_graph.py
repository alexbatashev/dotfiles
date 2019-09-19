import gdb
class SyclGraphPrinter(gdb.Command):
    "Print SYCL graph to file."
    def __init__ (self):
        super (SyclGraphPrinter, self).__init__ ("gprint",
                                                 gdb.COMMAND_SUPPORT,
                                                 gdb.COMPLETE_NONE, True)
    def invoke (self, arg, from_tty):
        gdb.execute("call printGraphAsDot(\"gdb\")")

