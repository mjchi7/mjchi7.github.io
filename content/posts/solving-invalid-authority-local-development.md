---
title: "HTTPS: Solving Invalid Authority for Local Development"
date: 2021-10-30T11:22:23+08:00
draft: true
---
## Seamless HTTPS Local Development Experience
If you are working on web app today, chances are (in fact 99% of the time) the production version will be 


Outline
- Introduction: motivation for setting up localhost tls. For example make experience much seamless instead of always pressing "proceed". Or even up to PWA stuff
- Idea: instead of just creating the cert, we'll first create a root CA. then, we'll create a signing request (csr) and use the rootCA to sign. Finally we add rootCA to trust store (AND REMEMBER to restart)
- Steps by steps
- Common Error: INVALID_COMMON_NAME: the field commonName (cn) is no longer used. We'll need to use the subjectAlternativeName (san)