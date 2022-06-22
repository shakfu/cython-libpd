from cysounddevice import PortAudio

pa = PortAudio()
pa.open()

print('DEVICES')
for i in pa.devices:
    print(i)


print('HOST-APIs')
for i in pa.host_apis:
    print(i)

pa.close()
