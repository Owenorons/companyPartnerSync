# Metadata Builder Tooling

This folder contains dev-only metadata generation assets that should not be
packaged or deployed with the PartnerSync managed package source.

Keep runtime Salesforce metadata under `force-app/main/default`. Keep generator
inputs, Metadata API helper Apex, scratch docs, and static JSON source files in
this tooling folder unless they become product runtime dependencies.
