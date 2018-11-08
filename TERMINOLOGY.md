# Terminology

To get a better understanding of how Lamia works you should keep in mind the meaning of the following terms.
Most of them overlap completely with Kubernetes or Istio entities, but some don't.

- **Project**: a project is a grouping of clusters. This will automatically be created by Lamia.
- **Cluster**: a cluster corresponds to a specific Kubernets clusters. Just like the Project, this will automatically be created by Lamia.
- **Virtual Cluster**: a virtual cluster is a partition of a Cluster and is represented by a Namespace in Kubernetes.
- **Application**: a grouping of related deployments, defined by a shared label.
- **Deployment**: a Kubernetes deployment which represents a specific version of an Application
- **Service**: a Kubernetes service associated with all Deployments of a given Application
- **Gateway**: an Istio Gateway exposing an Application Service
- **Destination Rule**: an Istio DestinationRule, which defines a subset of Deployments of one or several versions, based on common labels
- **Virtual Service**: an Istio VirtualService, which handles routing of requests towards Services
- **Vamp Service**: and abstraction that automatically sets up and manages a Service and its related Destination Rule and Virtual Service.
- **Policy**: an automated process that periodically performs actions over an entity. Currently only used for Gateways. For more details refer to the [Performing a canary release](#performing-a-canary-release) section. 
- **Experiment**: an automated process managing several resources involved in A/B testing a specific Vamp Service.
