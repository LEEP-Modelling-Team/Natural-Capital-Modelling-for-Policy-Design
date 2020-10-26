function index = fcn_get_wfd_lookup_index(ni,nn,wfd)
    index = 36 * (wfd-1) + 6 * (ni-1) + nn;
end