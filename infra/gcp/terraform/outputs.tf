output "gce_external_ip" { value = google_compute_instance.vm.network_interface[0].access_config[0].nat_ip }
output "cloud_run_url" { value = google_cloud_run_v2_service.app.uri }
output "cloud_functions_urls" { value = [for f in google_cloudfunctions2_function.fn : f.url] }