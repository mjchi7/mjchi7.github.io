---
title: "HTTPS: Solving Invalid Authority for Local Development"
date: 2021-10-30T11:22:23+08:00
draft: true
---
## Seamless HTTPS Local Development Experience
As most of the web app we are developing is running in the production over the HTTPS, it's only convenient if we are also setting it up as HTTPS in our local environment. However, one challenges we often face doing that is purchasing a certificate for local environment development doesn't make financial sense. Thus, usually what we do is to generate a self-signed certificate, often improperly. This results in the browser prompting about the invalid certificate presented by our web server on local. Although rarely causing issue, it serve as an hurdle to implementing PWA.

In this tutorial, we'll look at how can we set up HTTPS locally correctly, using self-signed certificate.

## High Level Idea
Generally, what we wanted to do would involve 4 distinct processes:

1. Creating a self-signed root Certificate Authority (CA)
2. Adding the self-signed root CA to trusted CA list
3. Creating a certificate signing request (CSR) for the domain of our web app
4. Signing the CSR using our self-signed root CA.

### 1. Creating a self-signed root CA
TLS/SSL works because there are several global root CA that we trust. On any operating systems, they come loaded with several of these global root CA in the trusted list.  
Root CA is at the end of the trust chain and serves as the ultimate trust authority in a series of trust chain. In essence, if we trust a particular root CA, we can trust any of the certificate signed by it, and any intermediary that's also signed by this root CA. 

A self signed root CA certificate is easy to generate


Outline
- Introduction: motivation for setting up localhost tls. For example make experience much seamless instead of always pressing "proceed". Or even up to PWA stuff
- Idea: instead of just creating the cert, we'll first create a root CA. then, we'll create a signing request (csr) and use the rootCA to sign. Finally we add rootCA to trust store (AND REMEMBER to restart)
- Steps by steps
- Common Error: INVALID_COMMON_NAME: the field commonName (cn) is no longer used. We'll need to use the subjectAlternativeName (san)


Reference
https://stackoverflow.com/a/60516812