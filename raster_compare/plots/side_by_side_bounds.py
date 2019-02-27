import math

import matplotlib.colors as colors
import matplotlib.pyplot as plt
import numpy
from matplotlib import cm

from .side_by_side import SideBySide


# Plot DEMs side by side
class SideBySideBounds(SideBySide):
    MIN_OUTLIER_VALUE = 190  # Adjust with histogram

    COLOR_MAP = 'CMRmap_r'
    BOUNDS_INTERVAL = 10

    def __init__(self, lidar, sfm, **kwargs):
        super().__init__(lidar, sfm, **kwargs)
        self._bounds = None

    @property
    def bounds(self):
        return self._bounds

    def bounds_from_data(self, raster_attr):
        min_value = math.floor(self.min_for_attr(raster_attr))
        max_value = math.ceil(self.max_for_attr(raster_attr))

        bounds = numpy.arange(
            min_value, self.MIN_OUTLIER_VALUE, self.BOUNDS_INTERVAL
        )
        self._bounds = numpy.append(bounds, [max_value])

    def im_opts(self, raster_attr):
        self.bounds_from_data(raster_attr)

        norm = colors.BoundaryNorm(boundaries=self.bounds, ncolors=256)

        return dict(
            cmap=cm.get_cmap(self.COLOR_MAP),
            norm=norm,
            alpha=0.5,
            vmin=self.bounds[0],
            vmax=self.bounds[-1],
        )

    def add_colorbar(self, cax, data):
        cbar = plt.colorbar(data, cax=cax)
        ticks = self.bounds[::2]
        ticks = numpy.append(ticks, self.bounds[-1])
        cbar.set_ticks(ticks)
        return cbar
