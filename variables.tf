variable "prefix" {
  description = "Prefix to prepend to resources e.g. company name"
  default = "Acme"
}
# Region to create resources
variable "location" {
  description = "Azure Region in which all resources will be created."
  default = "South Central US"
}
# TCP Ports for Security Group Rules
 variable "tcp_ports" {
    default = ["80",
               "443",
               "8080",
               "8443"]
 }

# UDP Ports for Security Group Rules
  variable "udp_ports" {
     default = ["53",
                "9090",
                "9443"]
   }
