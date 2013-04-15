#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <netdb.h>
#include <nss.h>
#include <resolv.h>
#include <arpa/inet.h>

void
prax_fill_hostent(const char *name,
                  int af,
                  struct hostent *result)
{
    result->h_name = malloc(sizeof(char) * strlen(name) + 1);
    strcpy(result->h_name, name);

    result->h_aliases = malloc(sizeof(char *));
    *result->h_aliases = NULL;

    result->h_addr_list = malloc(sizeof(char *) * 2);

    switch (af) {
    case AF_INET:
        result->h_addrtype = AF_INET;
        result->h_length = INADDRSZ;
        in_addr_t addr = inet_addr("127.0.0.1");
        *result->h_addr_list = malloc(sizeof(addr));
        memcpy(*result->h_addr_list, &addr, sizeof(addr));
        break;
    case AF_INET6:
        result->h_addrtype = AF_INET6;
        result->h_length = IN6ADDRSZ;
        struct in6_addr addr6 = {};
        inet_pton(AF_INET6, "::1", &addr6);
        *result->h_addr_list = malloc(sizeof(addr6));
        memcpy(*result->h_addr_list, &addr6, sizeof(addr6));
        break;
    }

    *(result->h_addr_list + 1) = NULL;
}

enum nss_status
_nss_prax_gethostbyname2_r(const char *name,
                           int af,
                           struct hostent *result,
                           char *buffer,
                           size_t buflen,
                           int *errnop,
                           int *h_errnop)
{
    enum nss_status status = NSS_STATUS_NOTFOUND;
    const char dot[1] = ".";
    char *ext;
    int len = 0;

    //FILE *log = fopen("/tmp/nss_prax.log","a+");
    //fprintf(log, "%s (%d)...", name, af);

    char *env = getenv("PRAX_DOMAINS");
    char *domains;
    if (env == NULL) {
        domains = strdup("dev");
    } else {
        domains = strdup(env);
    }

    char *domain = strtok(domains, ",");
    while (domain != NULL) {
        char *name_ext = strrchr(name, *dot);

        if (name_ext != NULL) {
            ext = malloc(sizeof(char) * (strlen(domain) + 2));
            sprintf(ext, ".%s", domain);

            if (strcasecmp(name_ext, ext) == 0) {
                status = NSS_STATUS_SUCCESS;
                prax_fill_hostent(name, af, result);
                free(ext);
                break;
            }
            free(ext);
        }
        domain = strtok(NULL, ",");
        len++;
    }

    //fprintf(log, " done.\n");
    //fclose(log);

    free(domains);
    return status;
}

enum nss_status
_nss_prax_gethostbyname_r(const char *name,
                          struct hostent *result,
                          char *buffer,
                          size_t buflen,
                          int *errnop,
                          int *h_errnop)
{
    return _nss_prax_gethostbyname2_r(name, AF_INET, result, buffer, buflen, errnop, h_errnop);
}

enum nss_status
_nss_gns_gethostbyaddr_r(const void *addr,
                         int len,
                         int af,
                         struct hostent *result,
                         char *buffer,
                         size_t buflen,
                         int *errnop,
                         int *h_errnop)
{
    return NSS_STATUS_UNAVAIL;
}

