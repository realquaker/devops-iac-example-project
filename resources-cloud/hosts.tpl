[cluster]
%{ for ip in cluster ~}
${ip}
%{ endfor ~}
