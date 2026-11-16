# The Assimilator: From ESP32 NAM Pedal to Open, Composable Rig-Cloning Platform

## Notes from an accidental product roadmap

This project did not begin as a plan to design a new audio interface, a capture appliance, a model-training orchestrator, a cross-ISA embedded platform, or a product family.

It began as a guitar pedal.

More precisely, it began as an effort to run Neural Amp Modeler-style inference on inexpensive ESP32 hardware, using whatever useful junk was already on hand: cheap USB audio interfaces, development boards, displays, footswitches, aluminum stompbox enclosures, and the usual assortment of cables whose failure modes are inversely proportional to how long one spends debugging firmware before suspecting them.

That modest beginning remains important. The project has expanded substantially, but the expansion has not invalidated the early prototypes. Instead, each new capability has suggested a natural next tier, and each tier remains useful in its own right.

The resulting architecture is starting to look less like uncontrolled scope creep and more like a deliberately composable product family whose development history happens to be visible.

The working flagship name is:

**The Assimilator**

The basic idea is increasingly simple to state:

> A standalone stompbox-scale device that can play amp models, capture rigs, create training data, outsource expensive model training when necessary, retrieve the resulting model, and then play the thing it just cloned.

The ludicrous version is easier:

> An infinite magic cloning device from the ISS Enterprise.

The useful version lies somewhere between them.

---

## 1. The original object: a small NAM pedal

The starting point was intentionally constrained.

A minimal pedal could run NAM models on an ESP32-S3 and provide basic control through a stomp switch. In headless operation, it can simply load a small default set of models and cycle through them with short taps.

That is already a perfectly usable device.

The early audio hardware did not need to be elegant. A JOYO MOMIX CAB and similarly inexpensive interfaces were available, class-compliant enough to prototype against, and therefore ideal for answering the first question:

**Can this be made to work at all on constrained embedded hardware?**

The answer was yes.

That first milestone matters because everything later can be judged against it. The project already has a useful minimum implementation rather than merely a collection of architectural aspirations.

The early design also established an important practical constraint: the ESP32-S3 is being pushed close to its useful real-time capacity. That makes every later architectural decision measurable rather than abstract. Display updates, USB audio handling, storage, radio use, capture, and model processing are not free.

The project therefore evolved around explicit operating states rather than attempting to do everything concurrently.

This was all inherited wholesale from Coyopedal. 

---

## 2. Performance mode and maintenance mode

A useful distinction emerged early, again initially from constraints and again inherited by virtue of our status initially as just a fork of Coyo. 

### Performance mode

Performance mode is optimized for the live audio path.

Its priorities are:

- low and predictable latency;
- uninterrupted audio processing;
- NAM inference;
- effects;
- simple footswitch interaction;
- model selection;
- minimal interference from nonessential subsystems.

The headless device can live almost entirely here.

### Maintenance mode

Maintenance mode allows operations that would be inappropriate or unnecessary during live performance.

This already includes activities such as:

- enabling radios;
- diagnostics;
- tone generation;
- loopback testing;
- configuration;
- firmware management;
- display-driven utilities.

The mode is toggled by approximately a two-second press of BOOT, with BOOT being rerouted to the footswitch in the enclosure. On display-equipped versions, the same transition can also be performed through the touchscreen UI.

This turned out to be more important than merely saving CPU cycles.

Maintenance mode became the obvious home for every future operation that temporarily changes the device from an effects processor into an instrument for understanding, testing, or modifying itself and connected equipment.

That naturally includes capture.

---

## 3. A screen appears, and the pedal grows a head

The next step was not a new product so much as a richer embodiment of the same one.

A display-equipped version can expose the same underlying functions through a touchscreen:

- model selection;
- effect selection;
- configuration;
- maintenance utilities;
- storage management;
- future capture workflows.

Various Waveshare ESP32-S3 display boards became development targets, including 2.8-inch and 4.3-inch boards.

The exact display size became something of a running joke as nearby hardware on the workbench repeatedly contaminated human memory of which panel was actually being discussed.

More importantly, this work exposed a software problem: support for display, touch, and microSD functionality was too board-specific.

That led to upstream work in Coyo/Geastack to improve composability rather than simply hard-coding another development board.

This was the first clear sign that the project had changed character.

The original task was "make my pedal work with this board."

The solution became "make the framework able to describe boards like this."

That distinction would later become central.

---

## 4. The project accidentally becomes a board-support problem

The work on display, touch, microSD, USB audio, and board configuration made one principle increasingly obvious:

**The hardware should be described by capabilities, not assumed from one blessed board.**

That led toward a composable model in which a build may or may not have:

- a display;
- touch;
- removable storage;
- particular audio hardware;
- radios;
- specific controls;
- capture-capable analog paths;
- network access.

This turns "headless" and "full UI" from separate applications into hardware capability profiles.

The application should behave appropriately for the hardware that exists.

A minimal device can expose three models and one footswitch.

A richer device can expose the same conceptual workflow through a touchscreen and SD-backed model library.

The software is the same project.

The embodiment changes.

That principle is what eventually makes the more ambitious tiers plausible instead of requiring a rewrite every time the hardware changes.

---

## 5. The tone generator quietly becomes the beginning of a capture system

Maintenance mode already contained a tone generator and loopback test.

That makes capture less of a foreign feature than it first appears.

The same basic infrastructure required to test audio paths can be extended into a measurement subsystem.

For impulse-response capture, the device can generate a known excitation signal, record the response, and perform or assist with deconvolution.

For NAM capture, the problem is more involved because the target system is nonlinear, but the conceptual machinery remains similar:

1. generate or play the required excitation;
2. route it through the device under test;
3. capture the reference and response signals;
4. validate the recording;
5. store the resulting training data;
6. pass the training set to an external compute resource;
7. retrieve and install the resulting model.

Maintenance mode therefore becomes the natural umbrella for:

```text
MAINTENANCE MODE
|
+-- Diagnostics
|   +-- Tone generator
|   +-- Loopback test
|   +-- Audio calibration
|
+-- Capture
|   +-- IR capture
|   +-- NAM capture
|   +-- Capture validation
|
+-- Model management
|   +-- SD import/export
|   +-- Remote training
|   +-- Model installation
|
+-- System
    +-- Network configuration
    +-- Firmware management
    +-- Hardware diagnostics
```

Capture need not become a third top-level operating mode. It can simply be an exclusive maintenance activity with its own lifecycle and resource ownership.

That is cleaner and preserves the existing user interaction model.

---

## 6. If it can capture the rig, it may as well train the model

Once the device can create NAM training captures, a practical problem appears:

The ESP32 is not the machine on which one wants to perform model training.

At first this seems like an obvious point at which the user must remove the SD card, copy files to a computer, launch a training environment, wait for training, copy the result back, and reinstall it.

But that workflow violates an emerging project instinct:

> If the user must connect a computer merely to complete a normal device workflow, perhaps the device has failed to finish the job.

There is already precedent.

The pedal uses its CH-series USB hardware to flash patched firmware directly onto connected JOYO hardware rather than requiring a separate external flashing step.

Once that exists, outsourcing model training begins to look less ridiculous.

Existing development scripts already allow commands to be sent to remote Colab environments, with resources spun up and shut down as needed. A production implementation should not necessarily depend specifically on Colab, but the workflow establishes the important abstraction:

```text
capture()
validate()
submit()
status()
retrieve()
install()
```

The pedal does not need to understand GPUs.

It needs to understand a training job.

The backend could be:

- a development Colab workflow;
- a workstation on the local network;
- a dedicated GPU server;
- an ephemeral cloud VM;
- some future training service.

MicroSD provides durable local job storage so that capture and training do not have to be a single fragile transaction.

A failed network connection need not mean repeating the physical capture session.

The device can also perform local preflight checks before provisioning expensive compute:

- clipping detection;
- signal-level validation;
- noise-floor checks;
- alignment checks;
- capture completeness;
- repeated-measurement consistency.

Only good captures get submitted.

At this point the pedal stops being merely a model player.

It becomes a model factory.

---

## 7. The first hardware fork: playback interface versus capture interface

The cheap JOYO and iRig-class devices were useful for rapid prototyping because they were already present and did enough to prove the concept.

They are not necessarily the right foundation for a serious capture appliance.

Playback and measurement have different requirements.

A path that sounds perfectly acceptable while playing a model may not be an ideal acquisition path for producing training data.

Capture raises questions of:

- input impedance;
- gain calibration;
- channel synchronization;
- converter quality;
- noise floor;
- headroom;
- deterministic latency;
- source and return routing;
- reamp-level output;
- line-level input;
- protection;
- clocking.

A proper tube amplifier introduces another boundary entirely.

A speaker output cannot simply be connected to an ordinary line input. Capturing tube amplifiers safely and meaningfully requires an appropriate load and attenuation scheme, and a reactive load may matter because the amplifier's behavior depends on its interaction with speaker impedance.

For prototypes, this argues for keeping the dangerous and power-dissipating load-box function external.

The Assimilator can provide the capture interface while a commercial reactive load provides the safe amplifier termination.

That boundary can remain explicit even in a polished product.

---

## 8. The realization: we need a good audio interface anyway

A second line of reasoning made the audio-hardware expansion much easier to justify.

Historically, devices such as the Roland GR-55 and VoiceLive Rack were convenient partly because they doubled as USB audio interfaces.

That convenience displaced dedicated interfaces.

Fewer cables and less setup friction often matter more in daily use than possessing technically superior hardware that lives in a closet.

The old Digi 002 eventually became impractical because Avid stopped supporting it in current software, though its motorized faders remain difficult to throw away.

A MOTU 828 still exists, but FireWire increasingly imposes the same kind of friction.

The Roland remains usable but its specifications are dated.

A recently acquired VoiceLive 3 Extreme does not function as the desired general USB audio interface.

Therefore a new USB-connected interface will likely be necessary regardless of the pedal project.

That changes the accounting.

The question is no longer:

> Why add the unnecessary complexity of building a good audio interface into a guitar pedal?

It becomes:

> If a new interface is needed anyway, and the rig-cloning device already needs quality ADC, DAC, clocking, routing, guitar-specific analog I/O, and USB audio, why buy those capabilities twice?

At that point, building a custom interface is no longer obviously irrational.

For a one-off commodity interface, DIY probably loses economically.

For an open-source product already requiring most of the same hardware, the arithmetic is different.

---

## 9. The audio subsystem should become a first-class component

The full-featured device should not merely contain "better audio."

It should contain an audio subsystem that remains useful as a proper interface.

A reasonable conceptual architecture is:

```text
                    USB-C
                      |
              USB AUDIO SUBSYSTEM
              -------------------
              UAC2 controller
              clocking
              ADC / DAC
              routing
              monitoring
                      |
          +-----------+-----------+
          |                       |
      Analog I/O               Compute
                               NAM / FX
                               Capture
                               UI
                               Storage
```

This implies a useful separation between:

### Audio board

Responsible for:

- converters;
- clocking;
- analog input stages;
- output stages;
- gain and attenuation;
- protection;
- direct monitoring;
- headphone output;
- potentially a dedicated UAC2 controller;
- routing between host, converters, and embedded processing.

### Compute/control board

Responsible for:

- NAM inference;
- effects;
- capture sequencing;
- display;
- touch;
- microSD;
- networking;
- configuration;
- training orchestration;
- footswitch logic.

This has several advantages.

The audio subsystem can remain viable if the compute platform changes.

The compute platform can be upgraded without redesigning all analog circuitry.

A flagship can eventually use a much more capable processor without invalidating the lower tiers.

It also becomes possible to ask whether the audio interface should remain operational even if the effects processor crashes or reboots.

For the flagship, the answer is probably yes.

That favors an independent UAC2-capable audio controller rather than making the real-time effects CPU responsible for every aspect of USB audio.

XMOS-class USB audio hardware is therefore worth investigating for the higher tiers, even if direct ESP32 USB remains attractive for smaller configurations.

---

## 10. Direct I2S still makes sense inside smaller builds

For the simpler pedal tiers, a different architecture remains attractive:

```text
ESP32-S3
   |
  I2S
   |
Audio codec
   |
Analog I/O
```

This removes USB host audio from the internal real-time path and gives direct control over DMA, clocking, buffering, and routing.

The ESP32-S3 can still potentially expose itself externally as a USB Audio Class device when desired.

That yields two distinct implementation strategies within the same project:

### Small / integrated tier

- ESP32 owns the codec;
- direct I2S audio path;
- ESP32 may expose UAC2 externally;
- low part count;
- appropriate for compact standalone pedals.

### Studio / flagship tier

- dedicated audio subsystem owns converters and USB streaming;
- embedded compute appears as a processing endpoint;
- interface remains useful independently;
- higher channel count and richer routing;
- compute platform can change without redesigning the interface.

The project does not need to choose one forever.

They are appropriate at different tiers.

---

## 11. The product ladder emerges naturally

The expanding ambitions map surprisingly cleanly onto increasingly capable prototypes.

Each tier is independently useful.

### Tier 0: Headless player

Minimal hardware.

- ESP32-S3;
- simple audio interface;
- footswitch;
- no display required;
- default model set;
- short tap cycles models;
- long press enters maintenance mode.

This is a real pedal, not a crippled prototype.

### Tier 1: Interactive player

Adds a head.

- display;
- touch;
- richer model/effect selection;
- settings UI;
- maintenance UI;
- optional removable storage.

Still fundamentally a standalone NAM/effects pedal.

### Tier 2: Capture appliance

Adds measurement capability.

- microSD;
- improved ADC/DAC path;
- IR capture;
- NAM training-data capture;
- calibration and validation;
- source/return routing.

Now the device can characterize external gear.

### Tier 3: Studio interface

The audio subsystem becomes independently respectable.

- class-compliant UAC2;
- 24-bit converters;
- useful modern sample rates;
- multiple synchronized inputs;
- multiple outputs;
- instrument input;
- line input;
- monitor path;
- headphone output;
- reamp-capable path;
- DAW usability;
- hardware/direct monitoring;
- standalone operation.

Now the device can replace a conventional interface for many sessions.

### Tier 4: Enterprise / Assimilator flagship

The complete workflow.

- capture;
- validation;
- removable storage;
- network orchestration;
- remote model training;
- automatic model retrieval;
- installation;
- live playback;
- polished UI;
- independent high-quality audio subsystem;
- more powerful compute platform if necessary.

This is the point at which the "rig cloner" language becomes mostly literal.

The development ladder can be summarized as:

```text
NAM player
    |
    v
NAM player + UI
    |
    v
NAM player + measurement
    |
    v
NAM player + serious UAC2 interface
    |
    v
capture -> train -> retrieve -> play
```

Nothing has to be thrown away along the way.

---

## 12. The tiers are development milestones, not necessarily SKUs

It would be premature to decide that every tier should become a commercial product.

The important point is that each tier is a valid build.

Eventually the project might ship two commercial devices while supporting many community configurations.

A possible future naming scheme might distinguish:

- a minimal headless pedal;
- an interactive pedal;
- a studio-oriented version;
- the full Assimilator Enterprise.

But the open-source project should not make the official product line the boundary of what hardware is allowed.

That would contradict how the project itself came into existence.

---

## 13. The architecture should preserve the experience, not the processor

A key realization is that the long-term product is not a particular ESP32 board.

The invariant is the operational model.

Every implementation should understand the same concepts:

- performance mode;
- maintenance mode;
- footswitch semantics;
- model loading;
- effect selection;
- capture sessions;
- model artifacts;
- persistent configuration;
- audio capabilities;
- optional display;
- optional storage;
- optional networking.

A headless ESP32-S3 can expose these concepts through one switch and a few models.

A flagship can expose them through a touchscreen, storage library, richer audio routing, and remote training.

The workflow remains recognizably the same.

This suggests a platform boundary above the board-support framework:

```text
                 ASSIMILATOR
                 APPLICATION
                      |
         +------------+------------+
         |            |            |
      Models       Capture        UI
         |            |            |
         +------------+------------+
                      |
                PLATFORM API
                      |
         +------------+------------+
         |            |            |
       ESP32         ARM         Other
         |            |            |
      Geastack       Linux       RTOS/DSP
         |            |            |
      Hardware      Hardware      Hardware
```

Geastack can remain the ESP32 hardware-composition layer.

Assimilator should consume its capabilities through an adapter rather than making Geastack itself the universal abstraction.

That leaves room for future Linux, ARM, DSP, or other implementations without diminishing the value of the ESP32 work.

---

## 14. The P4 is the first real portability test

The ESP32-P4 is already on the roadmap for a practical reason: there are two good development boards on the bench.

But it also creates an unusually useful architectural test.

The ESP32-S3 uses Xtensa LX7 cores.

The ESP32-P4 uses RISC-V.

Therefore moving NAM inference to the P4 is not merely "support another Espressif chip."

It forces a genuine ISA transition.

That matters because the current S3 implementation contains several hundred lines of Xtensa-specific optimized code.

Those optimized kernels cannot simply be recompiled unchanged for the P4.

However, initial research suggests that the port is not conceptually alien.

Espressif's SIMD facilities on the S3 and P4 differ in ISA and instruction syntax, but both expose explicit vector-style execution with similar high-level kernel organization.

The important structure survives:

```text
load vector(s)
perform vector operation / MAC
accumulate
store / reduce
loop
```

That makes the P4 a good intermediate challenge.

It forces the project to separate:

**what the NAM kernel means**

from

**how this processor executes it quickly enough**

A sensible structure is therefore:

```text
nam/
  kernels/
    reference/
    xtensa/
    riscv/
```

The portable/reference implementation serves as a correctness oracle.

The architecture-specific versions serve real-time performance.

The P4 port can proceed kernel by kernel:

```text
existing Xtensa kernel
        |
        +--> identify mathematical operation
        |
        +--> establish test vectors/output
        |
        +--> implement RISC-V/P4 SIMD equivalent
        |
        +--> validate against reference
        |
        +--> benchmark
        |
        +--> tune
```

This is more valuable than simply proving that the same C++ code compiles on another architecture.

It tests the ugly part: the performance-critical numerical code.

If that boundary survives one real ISA transition, confidence in future flagship portability becomes much more justified.

---

## 15. Do not require identical capability from every processor

Platform portability does not mean pretending every processor is equally powerful.

The same application can support different engine capabilities.

An ESP32-S3 may support:

- a restricted model class;
- limited model size;
- a specific sample rate;
- fewer simultaneous effects.

A P4 may support more.

A future flagship processor may support much larger models, higher sample rates, or more concurrent processing.

The UI and model-management workflow need not change.

The system simply exposes what the active engine can actually do.

That is real portability rather than lowest-common-denominator design.

---

## 16. Hardware inventory should become machine-readable

The project has reached the point where physical parts are becoming difficult to reason about informally.

There are:

- multiple ESP32 boards;
- multiple displays;
- various USB audio devices;
- potential codec boards;
- enclosures;
- stomp switches;
- microSD hardware;
- prospective donor devices;
- possible salvaged circuitry from dead rack equipment;
- future custom audio hardware.

A simple hardware inventory would prevent prototypes from becoming conceptual rather than buildable.

A useful structure might become:

```text
hardware/
|
+-- inventory.yaml
|
+-- profiles/
|   +-- headless.yaml
|   +-- interactive.yaml
|   +-- capture.yaml
|   +-- studio.yaml
|   +-- enterprise.yaml
|
+-- builds/
|   +-- headless-125b.yaml
|   +-- touchscreen-proto.yaml
|   +-- capture-proto.yaml
|   +-- enterprise-dev.yaml
|
+-- bom/
    +-- generated/
```

A profile describes required capabilities.

A build identifies actual parts satisfying them.

For example:

```yaml
name: Assimilator Capture Prototype

requires:
  processing:
    nam_inference: true

  audio:
    playback: true
    capture: true
    synchronized_inputs: 2

  controls:
    footswitch: true

  storage:
    removable: true

  maintenance:
    tone_generator: true
    loopback: true
    ir_capture: true
    nam_capture: true
```

Then:

```yaml
name: Waveshare Capture Build

profile: capture

components:
  controller: waveshare-esp32s3-2.8
  audio: TBD
  storage: microsd
  enclosure: TBD
  footswitch: momentary
```

Eventually a validation tool can report missing capabilities and generate BOMs automatically.

This also provides a clean place to distinguish:

- officially validated configurations;
- community-supported configurations;
- experimental configurations.

Open hardware support should not quietly become an obligation to personally guarantee every possible combination.

---

## 17. The analog subsystem deserves more respect than the marketing numbers

The flagship capture device should be designed around signal integrity rather than merely converter bit depth.

A useful target might include:

- 24-bit ADC/DAC;
- 44.1, 48, and 96 kHz interface operation;
- 48 kHz as an initial real-time NAM operating point;
- two synchronized inputs minimum;
- four inputs worth considering;
- multiple independent outputs;
- high-impedance instrument input;
- balanced line input where practical;
- dedicated or configurable reamp output;
- proper headphone amplifier;
- direct monitoring;
- good dynamic range;
- robust input protection;
- stable low-jitter clocking.

A 24-bit converter behind a poor input stage is not a high-quality interface.

Likewise, a nominally excellent DAC feeding an inappropriate guitar-amplifier input is not a faithful reamp path.

The analog front end should be treated as a first-class engineering problem.

A dead VoiceLive Rack may even provide useful donor hardware for prototyping: connectors, op-amps, power-supply circuitry, protection components, or portions of known-good analog stages.

Its converter silicon may or may not be convenient to reuse, depending on clocking, configuration, documentation, and how tightly it depends on the original processor.

Sometimes the dead rack unit is more valuable as an organ donor than as a schematic.

---

## 18. Four channels may age better than two

A simple stereo interface is enough to begin.

However, the capture use case creates pressure for more routing flexibility.

A useful rig-capture arrangement might want:

```text
             known excitation
                    |
                DAC OUT
                    |
               reamp stage
                    |
              device under test
                    |
             load / DI / return
                    |
                ADC IN 2

reference / delivered signal
                    |
                ADC IN 1
```

Meanwhile, independent stereo monitoring remains desirable.

That makes four DAC channels attractive:

- excitation / reamp;
- secondary test output;
- monitor left;
- monitor right.

Likewise, additional ADC channels could support more elaborate measurement or simultaneous reference capture.

The flagship audio subsystem should therefore be designed with channel-count growth in mind even if the first custom board is simpler.

---

## 19. Bypass and failure behavior matter because this is also a live device

The project is becoming more sophisticated, but it remains a stompbox.

That means failure behavior matters.

A useful architecture should consider:

- relay or analog bypass;
- hardware monitoring independent of inference;
- defined behavior if the compute subsystem crashes;
- preservation of the audio interface if the NAM engine reboots;
- safe handling of capture aborts;
- preventing accidental long-press mode changes during an active capture.

The full flagship should not become less dependable on stage merely because it can also summon remote GPUs.

The more theatrical the device becomes internally, the more boring its failure modes should become externally.

---

## 20. The project can remain open without requiring the official hardware

The project began because available hardware was useful and existing software did not quite support it.

That suggests an important long-term identity:

**The Assimilator should not require the Assimilator hardware.**

Official hardware can provide a polished, tested experience.

But the architecture should remain friendly to:

- spare development boards;
- community-designed PCBs;
- alternative displays;
- different codecs;
- custom control layouts;
- future processors;
- local modifications.

That creates a path for exactly the kind of contribution that started the current work:

> "I own this board. The framework almost supports it. I added the missing piece."

A healthy open-source project can then distinguish official support from community support without excluding experimentation.

This also gives the project an unusually appropriate slogan:

> **The Assimilator does not require you to buy its hardware. It assimilates yours.**

---

## 21. What the "Enterprise" really is

The Enterprise is not defined by one processor or enclosure.

It is the configuration in which enough capabilities are present for the complete loop:

```text
CONNECT TARGET RIG
        |
        v
GENERATE EXCITATION
        |
        v
CAPTURE RESPONSE
        |
        v
VALIDATE
        |
        v
STORE
        |
        v
PROVISION TRAINING COMPUTE
        |
        v
TRAIN MODEL
        |
        v
RETRIEVE MODEL
        |
        v
VALIDATE / INSTALL
        |
        v
PLAY THE CLONE
```

At that point, the device has become a kind of sonic replication appliance.

The original hardware can be returned unharmed.

Its continued existence is merely optional.

A suitably unnecessary UI might therefore display something like:

```text
TERRAN SONIC REPLICATION SYSTEM
================================

TARGET ACQUIRED

ANALYZING SUBJECT........ COMPLETE
EXTRACTING SONIC IDENTITY COMPLETE
REQUISITIONING COMPUTE... COMPLETE

NEURAL ASSIMILATION...... 73%

ORIGINAL HARDWARE........ CURRENTLY STILL NECESSARY
```

The last line should probably remain honest during early prototypes.

---

## 22. The expansion is the roadmap

The most useful conclusion from this discussion is that the project's growth does not need to be hidden or rewritten as if the final architecture were obvious at the beginning.

The development story is itself informative.

Each expansion came from encountering a concrete limitation or noticing that an adjacent capability reused work already required for the current one.

The sequence was approximately:

1. Make NAM run on an ESP32-S3.
2. Make the cheap USB audio path work.
3. Add a footswitch and useful headless operation.
4. Add displays, touch, and SD.
5. Improve upstream hardware composability rather than hard-code boards.
6. Formalize performance versus maintenance behavior.
7. Notice that tone generation and loopback are already capture primitives.
8. Add IR capture.
9. Realize NAM capture is the obvious next step.
10. Recognize that training can be outsourced rather than performed locally.
11. Reuse existing remote-compute automation.
12. Question whether cheap prototype interfaces are suitable for measurement.
13. Consider integrating a real audio interface.
14. Realize a new audio interface is needed personally anyway.
15. Turn the audio subsystem into a first-class component.
16. Preserve the same workflow across progressively more capable hardware.
17. Use the ESP32-P4 as the first real cross-ISA portability test.
18. Leave the eventual flagship free to use whatever compute platform best meets measured requirements.

Nothing in that sequence requires pretending that step 18 was secretly the plan during step 1.

More importantly, every intermediate state produces a useful artifact:

```text
headless pedal
     |
     v
interactive pedal
     |
     v
capture pedal
     |
     v
studio interface + processor
     |
     v
self-contained rig cloning appliance
```

That makes the scope expansion unusually defensible.

The project is not postponing usefulness until the grand design is complete.

It keeps producing useful machines while discovering what the larger machine wants to become.

---

## 23. Working architectural principles

The discussion leaves a useful set of principles that can guide further work.

### 1. Standalone first

Normal operation should not require a general-purpose computer.

### 2. Performance and maintenance are distinct operational concerns

Time-critical live processing should remain protected from optional maintenance work.

### 3. Capture belongs naturally inside maintenance mode

It is a controlled measurement operation, not a third everyday operating personality.

### 4. Hardware capabilities should be composed, not assumed

Display, touch, SD, audio, radios, and capture support should be independently describable.

### 5. The application should outlive any one board family

ESP32 is an implementation target, not the product definition.

### 6. Architecture-specific optimization is allowed

Portability does not require abandoning SIMD or processor-specific code.

It requires isolating it.

### 7. The portable implementation is the correctness oracle

Optimized kernels can differ radically internally while preserving model semantics.

### 8. Different hardware may expose different performance envelopes

The UI and workflow can remain consistent without pretending all processors support identical models.

### 9. The audio subsystem is a product in its own right

Especially at the upper tiers, UAC2, conversion, monitoring, and routing should not be treated as incidental accessories.

### 10. A computer should not be required merely because a workflow has an expensive step

Expensive compute can be provisioned remotely and treated as another resource.

### 11. Intermediate prototypes should remain useful

No tier should exist solely as disposable scaffolding for the next.

### 12. Open-source users should be able to assimilate their own hardware

Official builds can be tested and supported without closing the architecture.

---

## 24. Immediate next engineering questions

The project is broad enough now that the next steps should be driven by experiments rather than further speculation.

Near-term questions include:

1. How cleanly can the existing Xtensa-optimized NAM kernels be decomposed into reference semantics plus architecture-specific implementations?

2. How well does the P4 SIMD machinery map to the current S3 hot paths?

3. What is the actual P4 inference budget using the same benchmark models and audio block sizes?

4. Does a direct I2S codec path materially reduce overhead relative to the current USB-host audio implementation?

5. What converter and codec topology is appropriate for the first capture-grade prototype?

6. Is 2-in/2-out enough for the first measurement build, or is it worth beginning with a 4-channel-capable architecture?

7. Which guitar-specific analog paths are required: instrument input, line return, reamp output, monitor output, and headphone output?

8. What external reactive-load interface should define the safe tube-amplifier capture boundary?

9. At what tier does a dedicated USB audio controller become worth the added complexity?

10. Should the flagship audio subsystem remain independently enumerated and functional if the compute subsystem fails?

11. What hardware manifest format best maps current Geastack composition into higher-level Assimilator capabilities?

12. What is the minimum capture artifact format that can survive interrupted training, backend changes, and future model-generation tooling?

Those questions are concrete enough to answer experimentally.

That is probably the correct point at which to stop expanding the architecture on paper and return to making increasingly alarming noises with development boards.

---

## 25. A concise project statement

If the entire discussion had to be compressed into one description:

> **The Assimilator is an open, standalone, composable guitar-processing and rig-capture platform that begins as a small embedded NAM pedal and scales through touchscreen, storage, measurement, USB-audio, and remote-training capabilities into a self-contained hardware-cloning appliance. Its software workflow is intended to remain consistent across hardware tiers and processor architectures, while its open design allows community hardware to participate as first-class implementations.**

Or, for the box:

> **Connect. Capture. Assimilate. Stomp.**
