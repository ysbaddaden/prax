#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <netdb.h>
#include <nss.h>
#include <resolv.h>
#include <arpa/inet.h>

int str_split(char str[], char *sep, char **tokens) {
  int i = 0;
  char *tok = strtok(strdup(str), sep);
  while (tok != NULL) {
    tokens[i] = malloc(sizeof(char) * (strlen(tok) + 1));
    strcpy(tokens[i], tok);
    tok = strtok(NULL, sep);
    i++;
  }
  return i;
}

char *prax_get_domains() {
  char *domains = getenv("PRAX_DOMAINS");
  if (domains == NULL) {
    return strdup("dev");
  }
  return domains;
}

void
prax_fill_hostent(const char *name,
                  int af,
                  struct hostent *result)
{
  result->h_name = malloc(sizeof(char) * strlen(name) + 1);
  strcpy(result->h_name, name);

  result->h_aliases = malloc(sizeof(char *));
  *result->h_aliases = NULL;

  switch (af) {
  case AF_INET:
    result->h_addrtype = AF_INET;
    result->h_length = INADDRSZ;
    break;
  case AF_INET6:
    result->h_addrtype = AF_INET6;
    result->h_length = IN6ADDRSZ;
    break;
  }

  result->h_addr_list = malloc(sizeof(char *) * 2);
  *result->h_addr_list = malloc(sizeof(in_addr_t));
  in_addr_t addr = inet_addr("127.0.0.1");
  memcpy(*result->h_addr_list, &addr, sizeof(in_addr_t));
  *(result->h_addr_list + 1) = NULL;
}

char *prax_domains[0];
int prax_domains_len = 0;

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

  //FILE *log = fopen("/tmp/nss_prax.log","a+");
  //fprintf(log, "%s (%d)\n", name, af);
  //fclose(log);

  if (prax_domains_len == 0) {
    prax_domains_len = str_split(prax_get_domains(), ",", prax_domains);
  }

  const char dot[1] = ".";
  char *ext;
  int i;
  for (i = 0; i < prax_domains_len; i++) {
    char *name_ext = strrchr(name, *dot);
    if (name_ext != NULL) {
      ext = malloc(sizeof(char) * (strlen(prax_domains[i]) + 1));
      sprintf(ext, ".%s", prax_domains[i]);
      if (strcasecmp(name_ext, ext) == 0) {
        prax_fill_hostent(name, af, result);
        status = NSS_STATUS_SUCCESS;
        break;
      }
      free(ext);
    }
  }

  //free(prax_domains);
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

//int main(void) {
//  char *buffer;
//  int *errnop;
//  int *h_errnop;
//
//  const char *name = "tellicious.dev";
//  struct hostent *result = malloc(sizeof(struct hostent));
//  printf("%d\n", _nss_prax_gethostbyname_r(name, result, buffer, 0, errnop, h_errnop));
//
//  const char *name2 = "abcdefghik";
//  struct hostent *result2 = malloc(sizeof(struct hostent));
//  printf("%d\n", _nss_prax_gethostbyname_r(name2, result2, buffer, 0, errnop, h_errnop));
//
//  return EXIT_SUCCESS;
//}
