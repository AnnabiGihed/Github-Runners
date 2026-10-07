# Dedicated Linux VM option

Status: explained to the user; not selected or implemented.

## Shape

Windows PC → dedicated Linux VM → Docker → fresh runner and job-local Docker engine per job. A trusted controller provisions and removes the job environments. Runner bootstrap uses GitHub Apps and outbound HTTPS; no incoming ports, SSH port forwarding, webhook listener, or Docker TCP endpoint is required. Administration may use the hypervisor console.

The VM keeps running while the PC is available. Job containers, workspaces, nested engine state, and service containers are disposable. This satisfies Docker-hosted runners; it does not imply a fresh VM for every job.

## Isolation

A VM has its own Linux kernel, providing a boundary between nested Docker jobs and the Windows host. Ordinary Docker containers in one VM still share that VM's kernel. Privileged job-local Docker may be needed for compatibility; moving it into a VM confines its authority better than running it in the personal Docker environment but does not make jobs mutually isolated or safe for hostile workflows.

Keep host folder sharing, clipboard integration, App keys, and controller state out of job environments. Restrict job networks and assess LAN reachability. Do not mount the VM's host Docker socket into a runner. A VM escape or compromise of the provisioning VM remains a risk; truly untrusted jobs may need separate disposable VMs rather than this shared VM design.

## Capacity and reuse

The approved initial budget is 8 virtual CPUs and 16 GiB RAM, with a four-job total cap and two jobs per target. Apply the budget to the selected backend; do not allocate it twice to both a VM and Docker Desktop. Validate representative build/service workloads before declaring four-job capacity sustainable. Current free D: space is approximately 414.7 GiB; VM disk size is undecided.

Target configuration and common runner images remain reusable for other repositories/organizations. VM setup, console administration, patching, startup, image updates, diagnostics, and recovery require saved automation and documented runbooks. Hypervisor choice, OS/image pinning, network policy, disk sizing, and startup behavior are still pending.

## Tradeoff

This adds a guest OS and hypervisor setup, maintenance, and resource overhead. It gives nested Docker a separate kernel environment and avoids mixing jobs with the user's personal Docker workloads. Running privileged job-local Docker directly under Docker Desktop is simpler, but exposes its shared Linux engine/kernel to more workflow authority. Neither design eliminates the need for trusted workflows and isolated credentials.
