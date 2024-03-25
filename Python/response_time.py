import matplotlib
matplotlib.use('TkAgg')
import matplotlib.pyplot as plt
import numpy as np
import statistics
from scipy.stats import norm

with open(r"C:\Users\danie\Desktop\school\ECE 4415\dt.txt","r") as txt_file:
    data = txt_file.readlines()

    data = [float(d[:-1]) for d in data]

print(len(data))
print("mean: " + str(statistics.mean(data)) + " std: " + str(statistics.stdev(data)) + ", range: " + str(min(data)) + " - " + str(max(data)))

mu, std = norm.fit(data)

# Plot the histogram.
plt.hist(data, bins=4, alpha=0.6, color='b')

# Plot the PDF.
# xmin, xmax = plt.xlim()
# x = np.linspace(xmin, xmax, 100)
# p = norm.pdf(x, mu, std)
#
# plt.plot(x, p, 'k', linewidth=2)
#title = "Fit Values: {:.2f} and {:.2f}".format(mu, std)
plt.title("Controller Latency Histogram")
plt.xlabel("Microseconds")
plt.ylabel("Count")

plt.show()

