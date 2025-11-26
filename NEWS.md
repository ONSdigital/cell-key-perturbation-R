
# cellkeyperturbation 2.0.0

* New threshold parameter added (with default of 10) for the create_perturbed_table function. Counts < threshold will be set to missing. This means that the user will not need to go through an additional process to suppress small counts after applying perturbation.

* Warnings if any records are missing record keys and exception raised if percentage with record keys < 50%.

* The 'record_key_arg' parameter renamed to 'record_key' to match the Python implementation.

# cellkeyperturbation 1.0.0

* First release

# cellkeyperturbation (development version 0.0.0.9000)


