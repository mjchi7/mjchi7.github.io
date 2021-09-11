---
title: "Istio: Sporadic 503 Error"
date: 2021-09-11T17:33:20+08:00
draft: true
subtitle: "A curious tale of sporadic 503 errors in Istio service mesh"
---
## Random 503 Errors
Using Istio service mesh in production, I've often come across error logs that reports an observation of 503 errors with the response flags "UC". Particularly, the logs come from the `istio-proxy` sidecar that runs alongside the microservice. 

Looking up the "UC" flag in Envoy documentation, it means, and I quote verbatim:
>> *UC*: Upstream connection termination in addition to 503 response code.

What's more puzzling is the fact that while the proxy reports a 503 response code, none of the client has actually observe 503 error from their perspectives.
In this article, let's dive deep into this issue through experimentation.

## Upstream, Downstream?
One thing that confuses me a lot is the term "upstream" and "downstream" in the context of internet connection. To put it simply, the request caller is the "downstream" and the request processor is the "upstream". 
The confusion arises when `istio-proxy` can be either an "upstream" or "downstream", depending on the perspective we are looking from. 
If we are talking about the connection between the load balancer with `istio-proxy`, then the sidecar is considered an "upstream". 

On the other hand, the `istio-proxy` is the downstream party when we are looking at the relationship between the sidecar and the actual microservice.

## "Upstream connection termination"
By getting a firm grasp of the up downstream terminology, we can now examine the error message in details. If we look again at the meaning of the "UC" response flag:

>> *UC*: Upstream connection termination in addition to 503 response code.

It says that the "upstream" is terminating the connection. Now we know that the log is obtained from the sidecar `istio-proxy`, hence the upstream here is referring to the microservice it is serving. Concretely, it is saying that our microservice is terminating the connection.