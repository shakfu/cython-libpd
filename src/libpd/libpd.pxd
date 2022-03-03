
cdef extern from "pd/m_pd.h":
    """
    #undef T_OBJECT
    """
    ctypedef float t_float
    ctypedef struct t_pdinstance
    ctypedef float t_floatarg
    ctypedef float t_sample
    ctypedef long t_int

    ctypedef struct t_symbol:
        const char *s_name
        # struct _class **s_thing
        # struct _symbol *s_next


    ctypedef union t_word:
        t_float w_float
        t_symbol *w_symbol
        # t_gpointer *w_gpointer
        # t_array *w_array
        # struct _binbuf *w_binbuf
        # int w_index

    ctypedef enum t_atomtype:
        A_NULL
        A_FLOAT
        A_SYMBOL
        A_POINTER
        A_SEMI
        A_COMMA
        A_DEFFLOAT
        A_DEFSYM
        A_DOLLAR
        A_DOLLSYM
        A_GIMME
        A_CANT

    ctypedef struct t_atom:
        t_atomtype a_type
    #     union word a_w


    # memory mgmt
    void *getbytes(size_t nbytes)
    void *getzbytes(size_t nbytes)
    void *copybytes(const void *src, size_t nbytes)
    void freebytes(void *x, size_t nbytes)
    void *resizebytes(void *x, size_t oldsize, size_t newsize)

    # key funcs
    t_symbol *gensym(const char *s)


    # atom ops
    void SETFLOAT(t_atom *atom, float f)
    void SETSYMBOL(t_atom *atom, char *s)

    # conversion
    t_float atom_getfloat(const t_atom *a)
    t_int atom_getint(const t_atom *a)
    t_symbol *atom_getsymbol(const t_atom *a)
    t_symbol *atom_gensym(const t_atom *a)
    t_float atom_getfloatarg(int which, int argc, const t_atom *argv)
    t_int atom_getintarg(int which, int argc, const t_atom *argv)
    t_symbol *atom_getsymbolarg(int which, int argc, const t_atom *argv)
    void atom_string(const t_atom *a, char *buf, unsigned int bufsize)


cdef extern from "pd/z_libpd.h":

## initialization

    # initialize libpd; it is safe to call this more than once
    # returns 0 on success or -1 if libpd was already initialized
    # note: sets SIGFPE handler to keep bad pd patches from crashing due to divide
    #       by 0, set any custom handling after calling this function
    int libpd_init()

    # clear the libpd search path for abstractions and externals
    # note: this is called by libpd_init()
    void libpd_clear_search_path()

    # add a path to the libpd search paths
    # relative paths are relative to the current working directory
    # unlike desktop pd, *no* search paths are set by default (ie. extra)
    void libpd_add_to_search_path(const char *path)

## opening patches

    # open a patch by filename and parent dir path
    # returns an opaque patch handle pointer or NULL on failure
    void *libpd_openfile(const char *name, const char *dir)

    # close a patch by patch handle pointer
    void libpd_closefile(void *p) nogil

    # get the $0 id of the patch handle pointer
    # returns $0 value or 0 if the patch is non-existent
    int libpd_getdollarzero(void *p)

## audio processing

    # return pd's fixed block size: the number of sample frames per 1 pd tick
    int libpd_blocksize()

    # initialize audio rendering
    # returns 0 on success
    int libpd_init_audio(int inChannels, int outChannels, int sampleRate)

    # process interleaved float samples from inBuffer -> libpd -> outBuffer
    # buffer sizes are based on # of ticks and channels where:
    #     size = ticks * libpd_blocksize() * (in/out)channels
    # returns 0 on success
    int libpd_process_float(const int ticks,
        const float *inBuffer, float *outBuffer) nogil

    # process interleaved short samples from inBuffer -> libpd -> outBuffer
    # buffer sizes are based on # of ticks and channels where:
    #     size = ticks * libpd_blocksize() * (in/out)channels
    # float samples are converted to short by multiplying by 32767 and casting,
    # so any values received from pd patches beyond -1 to 1 will result in garbage
    # note: for efficiency, does *not* clip input
    # returns 0 on success
    int libpd_process_short(const int ticks,
        const short *inBuffer, short *outBuffer) nogil

    # process interleaved double samples from inBuffer -> libpd -> outBuffer
    # buffer sizes are based on # of ticks and channels where:
    #     size = ticks * libpd_blocksize() * (in/out)channels
    # returns 0 on success
    int libpd_process_double(const int ticks,
        const double *inBuffer, double *outBuffer) nogil

    # process non-interleaved float samples from inBuffer -> libpd -> outBuffer
    # copies buffer contents to/from libpd without striping
    # buffer sizes are based on a single tick and # of channels where:
    #     size = libpd_blocksize() * (in/out)channels
    # returns 0 on success
    int libpd_process_raw(const float *inBuffer, float *outBuffer) nogil

    # process non-interleaved short samples from inBuffer -> libpd -> outBuffer
    # copies buffer contents to/from libpd without striping
    # buffer sizes are based on a single tick and # of channels where:
    #     size = libpd_blocksize() * (in/out)channels
    # float samples are converted to short by multiplying by 32767 and casting,
    # so any values received from pd patches beyond -1 to 1 will result in garbage
    # note: for efficiency, does *not* clip input
    # returns 0 on success
    int libpd_process_raw_short(const short *inBuffer, short *outBuffer) nogil

    # process non-interleaved double samples from inBuffer -> libpd -> outBuffer
    # copies buffer contents to/from libpd without striping
    # buffer sizes are based on a single tick and # of channels where:
    #     size = libpd_blocksize() * (in/out)channels
    # returns 0 on success
    int libpd_process_raw_double(const double *inBuffer, double *outBuffer) nogil

## atom creation

    # write a float value to the given atom
    void libpd_set_float(t_atom *a, float x)

    # write a symbol value to the given atom
    void libpd_set_symbol(t_atom *a, const char *symbol)

## array access

    # get the size of an array by name
    # returns size or negative error code if non-existent
    int libpd_arraysize(const char *name)

    # (re)size an array by name sizes <= 0 are clipped to 1
    # returns 0 on success or negative error code if non-existent
    int libpd_resize_array(const char *name, long size)

    # read n values from named src array and write into dest starting at an offset
    # note: performs no bounds checking on dest
    # returns 0 on success or a negative error code if the array is non-existent
    # or offset + n exceeds range of array
    int libpd_read_array(float *dest, const char *name, int offset, int n)

    # read n values from src and write into named dest array starting at an offset
    # note: performs no bounds checking on src
    # returns 0 on success or a negative error code if the array is non-existent
    # or offset + n exceeds range of array
    int libpd_write_array(const char *name, int offset, const float *src, int n)

## sending messages to pd

    # send a bang to a destination receiver
    # ex: libpd_bang("foo") will send a bang to [s foo] on the next tick
    # returns 0 on success or -1 if receiver name is non-existent
    int libpd_bang(const char *recv)

    # send a float to a destination receiver
    # ex: libpd_float("foo", 1) will send a 1.0 to [s foo] on the next tick
    # returns 0 on success or -1 if receiver name is non-existent
    int libpd_float(const char *recv, float x)

    # send a symbol to a destination receiver
    # ex: libpd_symbol("foo", "bar") will send "bar" to [s foo] on the next tick
    # returns 0 on success or -1 if receiver name is non-existent
    int libpd_symbol(const char *recv, const char *symbol)

## sending compound messages: sequenced function calls

    # start composition of a new list or typed message of up to max element length
    # messages can be of a smaller length as max length is only an upper bound
    # note: no cleanup is required for unfinished messages
    # returns 0 on success or nonzero if the length is too large
    int libpd_start_message(int maxlen)

    # add a float to the current message in progress
    void libpd_add_float(float x)

    # add a symbol to the current message in progress
    void libpd_add_symbol(const char *symbol)

    # finish current message and send as a list to a destination receiver
    # returns 0 on success or -1 if receiver name is non-existent
    # ex: send [list 1 2 bar( to [s foo] on the next tick with:
    #     libpd_start_message(3)
    #     libpd_add_float(1)
    #     libpd_add_float(2)
    #     libpd_add_symbol("bar")
    #     libpd_finish_list("foo")
    int libpd_finish_list(const char *recv)

    # finish current message and send as a typed message to a destination receiver
    # note: typed message handling currently only supports up to 4 elements
    #       internally, additional elements may be ignored
    # returns 0 on success or -1 if receiver name is non-existent
    # ex: send [ pd dsp 1( on the next tick with:
    #     libpd_start_message(1)
    #     libpd_add_float(1)
    #     libpd_finish_message("pd", "dsp")
    int libpd_finish_message(const char *recv, const char *msg)


## sending compound messages: atom array

    # send an atom array of a given length as a list to a destination receiver
    # returns 0 on success or -1 if receiver name is non-existent
    # ex: send [list 1 2 bar( to [r foo] on the next tick with:
    #     t_atom v[3]
    #     libpd_set_float(v, 1)
    #     libpd_set_float(v + 1, 2)
    #     libpd_set_symbol(v + 2, "bar")
    #     libpd_list("foo", 3, v)
    int libpd_list(const char *recv, int argc, t_atom *argv)

    # send a atom array of a given length as a typed message to a destination
    # receiver, returns 0 on success or -1 if receiver name is non-existent
    # ex: send [ pd dsp 1( on the next tick with:
    #     t_atom v[1]
    #     libpd_set_float(v, 1)
    #     libpd_message("pd", "dsp", 1, v)
    int libpd_message(const char *recv, const char *msg, int argc, t_atom *argv)

## receiving messages from pd

    # subscribe to messages sent to a source receiver
    # ex: libpd_bind("foo") adds a "virtual" [r foo] which forwards messages to
    #     the libpd message hooks
    # returns an opaque receiver pointer or NULL on failure
    void *libpd_bind(const char *recv)

    # unsubscribe and free a source receiver object created by libpd_bind()
    void libpd_unbind(void *p)

    # check if a source receiver object exists with a given name
    # returns 1 if the receiver exists, otherwise 0
    int libpd_exists(const char *recv)

    # print receive hook signature, s is the string to be printed
    # note: default behavior returns individual words and spaces:
    #     line "hello 123" is received in 4 parts -> "hello", " ", "123\n"
    ctypedef void (*t_libpd_printhook)(const char *s)

    # bang receive hook signature, recv is the source receiver name
    ctypedef void (*t_libpd_banghook)(const char *recv)

    # float receive hook signature, recv is the source receiver name
    ctypedef void (*t_libpd_floathook)(const char *recv, float x)

    # symbol receive hook signature, recv is the source receiver name
    ctypedef void (*t_libpd_symbolhook)(const char *recv, const char *symbol)

    # list receive hook signature, recv is the source receiver name
    # argc is the list length and vector argv contains the list elements
    # which can be accessed using the atom accessor functions, ex:
    #     int i
    #     for (i = 0 i < argc i++) {
    #       t_atom *a = &argv[n]
    #       if (libpd_is_float(a)) {
    #         float x = libpd_get_float(a)
    #         // do something with float x
    #       } else if (libpd_is_symbol(a)) {
    #         char *s = libpd_get_symbol(a)
    #         // do something with c string s
    #       }
    #     }
    # note: check for both float and symbol types as atom may also be a pointer
    ctypedef void (*t_libpd_listhook)(const char *recv, int argc, t_atom *argv)

    # typed message hook signature, recv is the source receiver name and msg is
    # the typed message name: a message like [ foo bar 1 2 a b( will trigger a
    # function call like libpd_messagehook("foo", "bar", 4, argv)
    # argc is the list length and vector argv contains the
    # list elements which can be accessed using the atom accessor functions, ex:
    #     int i
    #     for (i = 0 i < argc i++) {
    #       t_atom *a = &argv[n]
    #       if (libpd_is_float(a)) {
    #         float x = libpd_get_float(a)
    #         // do something with float x
    #       } else if (libpd_is_symbol(a)) {
    #         char *s = libpd_get_symbol(a)
    #         // do something with c string s
    #       }
    #     }
    # note: check for both float and symbol types as atom may also be a pointer
    ctypedef void (*t_libpd_messagehook)(const char *recv, const char *msg,
        int argc, t_atom *argv)

    # set the print receiver hook, prints to stdout by default
    # note: do not call this while DSP is running
    void libpd_set_printhook(const t_libpd_printhook hook)

    # set the bang receiver hook, NULL by default
    # note: do not call this while DSP is running
    void libpd_set_banghook(const t_libpd_banghook hook)

    # set the float receiver hook, NULL by default
    # note: do not call this while DSP is running
    void libpd_set_floathook(const t_libpd_floathook hook)

    # set the symbol receiver hook, NULL by default
    # note: do not call this while DSP is running
    void libpd_set_symbolhook(const t_libpd_symbolhook hook)

    # set the list receiver hook, NULL by default
    # note: do not call this while DSP is running
    void libpd_set_listhook(const t_libpd_listhook hook)

    # set the message receiver hook, NULL by default
    # note: do not call this while DSP is running
    void libpd_set_messagehook(const t_libpd_messagehook hook)

    # check if an atom is a float type: 0 or 1
    # note: no NULL check is performed
    int libpd_is_float(t_atom *a)

    # check if an atom is a symbol type: 0 or 1
    # note: no NULL check is performed
    int libpd_is_symbol(t_atom *a)

    # get the float value of an atom
    # note: no NULL or type checks are performed
    float libpd_get_float(t_atom *a)

    # note: no NULL or type checks are performed
    # get symbol value of an atom
    const char *libpd_get_symbol(t_atom *a)

    # increment to the next atom in an atom vector
    # returns next atom or NULL, assuming the atom vector is NULL-terminated
    t_atom *libpd_next_atom(t_atom *a)

## sending MIDI messages to pd

    # send a MIDI note on message to [notein] objects
    # channel is 0-indexed, pitch is 0-127, and velocity is 0-127
    # channels encode MIDI ports via: libpd_channel = pd_channel + 16 * pd_port
    # note: there is no note off message, send a note on with velocity = 0 instead
    # returns 0 on success or -1 if an argument is out of range
    int libpd_noteon(int channel, int pitch, int velocity)

    # send a MIDI control change message to [ctlin] objects
    # channel is 0-indexed, controller is 0-127, and value is 0-127
    # channels encode MIDI ports via: libpd_channel = pd_channel + 16 * pd_port
    # returns 0 on success or -1 if an argument is out of range
    int libpd_controlchange(int channel, int controller, int value)

    # send a MIDI program change message to [pgmin] objects
    # channel is 0-indexed and value is 0-127
    # channels encode MIDI ports via: libpd_channel = pd_channel + 16 * pd_port
    # returns 0 on success or -1 if an argument is out of range
    int libpd_programchange(int channel, int value)

    # send a MIDI pitch bend message to [bendin] objects
    # channel is 0-indexed and value is -8192-8192
    # channels encode MIDI ports via: libpd_channel = pd_channel + 16 * pd_port
    # note: [bendin] outputs 0-16383 while [bendout] accepts -8192-8192
    # returns 0 on success or -1 if an argument is out of range
    int libpd_pitchbend(int channel, int value)

    # send a MIDI after touch message to [touchin] objects
    # channel is 0-indexed and value is 0-127
    # channels encode MIDI ports via: libpd_channel = pd_channel + 16 * pd_port
    # returns 0 on success or -1 if an argument is out of range
    int libpd_aftertouch(int channel, int value)

    # send a MIDI poly after touch message to [polytouchin] objects
    # channel is 0-indexed, pitch is 0-127, and value is 0-127
    # channels encode MIDI ports via: libpd_channel = pd_channel + 16 * pd_port
    # returns 0 on success or -1 if an argument is out of range
    int libpd_polyaftertouch(int channel, int pitch, int value)

    # send a raw MIDI byte to [midiin] objects
    # port is 0-indexed and byte is 0-256
    # returns 0 on success or -1 if an argument is out of range
    int libpd_midibyte(int port, int byte)

    # send a raw MIDI byte to [sysexin] objects
    # port is 0-indexed and byte is 0-256
    # returns 0 on success or -1 if an argument is out of range
    int libpd_sysex(int port, int byte)

    # send a raw MIDI byte to [realtimein] objects
    # port is 0-indexed and byte is 0-256
    # returns 0 on success or -1 if an argument is out of range
    int libpd_sysrealtime(int port, int byte)

## receiving MIDI messages from pd

    # MIDI note on receive hook signature
    # channel is 0-indexed, pitch is 0-127, and value is 0-127
    # channels encode MIDI ports via: libpd_channel = pd_channel + 16 * pd_port
    # note: there is no note off message, note on w/ velocity = 0 is used instead
    # note: out of range values from pd are clamped
    ctypedef void (*t_libpd_noteonhook)(int channel, int pitch, int velocity)

    # MIDI control change receive hook signature
    # channel is 0-indexed, controller is 0-127, and value is 0-127
    # channels encode MIDI ports via: libpd_channel = pd_channel + 16 * pd_port
    # note: out of range values from pd are clamped
    ctypedef void (*t_libpd_controlchangehook)(int channel,
        int controller, int value)

    # MIDI program change receive hook signature
    # channel is 0-indexed and value is 0-127
    # channels encode MIDI ports via: libpd_channel = pd_channel + 16 * pd_port
    # note: out of range values from pd are clamped
    ctypedef void (*t_libpd_programchangehook)(int channel, int value)

    # MIDI pitch bend receive hook signature
    # channel is 0-indexed and value is -8192-8192
    # channels encode MIDI ports via: libpd_channel = pd_channel + 16 * pd_port
    # note: [bendin] outputs 0-16383 while [bendout] accepts -8192-8192
    # note: out of range values from pd are clamped
    ctypedef void (*t_libpd_pitchbendhook)(int channel, int value)

    # MIDI after touch receive hook signature
    # channel is 0-indexed and value is 0-127
    # channels encode MIDI ports via: libpd_channel = pd_channel + 16 * pd_port
    # note: out of range values from pd are clamped
    ctypedef void (*t_libpd_aftertouchhook)(int channel, int value)

    # MIDI poly after touch receive hook signature
    # channel is 0-indexed, pitch is 0-127, and value is 0-127
    # channels encode MIDI ports via: libpd_channel = pd_channel + 16 * pd_port
    # note: out of range values from pd are clamped
    ctypedef void (*t_libpd_polyaftertouchhook)(int channel, int pitch, int value)

    # raw MIDI byte receive hook signature
    # port is 0-indexed and byte is 0-256
    # note: out of range values from pd are clamped
    ctypedef void (*t_libpd_midibytehook)(int port, int byte)

    # set the MIDI note on hook to receive from [noteout] objects, NULL by default
    # note: do not call this while DSP is running
    void libpd_set_noteonhook(const t_libpd_noteonhook hook)

    # set the MIDI control change hook to receive from [ctlout] objects,
    # NULL by default
    # note: do not call this while DSP is running
    void libpd_set_controlchangehook(const t_libpd_controlchangehook hook)

    # set the MIDI program change hook to receive from [pgmout] objects,
    # NULL by default
    # note: do not call this while DSP is running
    void libpd_set_programchangehook(const t_libpd_programchangehook hook)

    # set the MIDI pitch bend hook to receive from [bendout] objects,
    # NULL by default
    # note: do not call this while DSP is running
    void libpd_set_pitchbendhook(const t_libpd_pitchbendhook hook)

    # set the MIDI after touch hook to receive from [touchout] objects,
    # NULL by default
    # note: do not call this while DSP is running
    void libpd_set_aftertouchhook(const t_libpd_aftertouchhook hook)

    # set the MIDI poly after touch hook to receive from [polytouchout] objects,
    # NULL by default
    # note: do not call this while DSP is running
    void libpd_set_polyaftertouchhook(const t_libpd_polyaftertouchhook hook)

    # set the raw MIDI byte hook to receive from [midiout] objects,
    # NULL by default
    # note: do not call this while DSP is running
    void libpd_set_midibytehook(const t_libpd_midibytehook hook)

## GUI

    # open the current patches within a pd vanilla GUI
    # requires the path to pd's main folder that contains bin/, tcl/, etc
    # for a macOS .app bundle: /path/to/Pd-#.#-#.app/Contents/Resources
    # returns 0 on success
    int libpd_start_gui(char *path)

    # stop the pd vanilla GUI
    void libpd_stop_gui()

    # manually update and handle any GUI messages
    # this is called automatically when using a libpd_process function,
    # note: this also facilitates network message processing, etc so it can be
    #       useful to call repeatedly when idle for more throughput
    void libpd_poll_gui()

## multiple instances

    # create a new pd instance
    # returns new instance or NULL when libpd is not compiled with PDINSTANCE
    t_pdinstance *libpd_new_instance()

    # set the current pd instance
    # subsequent libpd calls will affect this instance only
    # does nothing when libpd is not compiled with PDINSTANCE
    void libpd_set_instance(t_pdinstance *p)

    # free a pd instance
    # does nothing when libpd is not compiled with PDINSTANCE
    void libpd_free_instance(t_pdinstance *p)

    # get the current pd instance
    t_pdinstance *libpd_this_instance()

    # get a pd instance by index
    # returns NULL if index is out of bounds or "this" instance when libpd is not
    # compiled with PDINSTANCE
    t_pdinstance *libpd_get_instance(int index)

    # get the number of pd instances
    # returns number or 1 when libpd is not compiled with PDINSTANCE
    int libpd_num_instances()

## log level

    # set verbose print state: 0 or 1
    void libpd_set_verbose(int verbose)

    # get the verbose print state: 0 or 1
    int libpd_get_verbose()
