import datetime
import decimal
import os

import pandas

from images_time_table.base import ImagesMetaCsv


class SbetFile(object):
    GPS_COLUMN = 'GpsTime'
    GPS_TIME_WINDOW = 0.05
    GPS_LEAP_SECONDS = 18  # since 2017
                           # 17s from 2015 - 2017
                           # 16s from 2012 - 2015

    SBET_CSV_FILE_NAME = 'sbet.csv'
    SBET_DIR = 'SBET'
    SBET_CSV_DTYPES = {
        'X': decimal.Decimal,
        'Y': decimal.Decimal,
        'Z': decimal.Decimal,
        'Roll': decimal.Decimal,
        'Pitch': decimal.Decimal,
        'Heading': decimal.Decimal,
    }

    def __init__(self, base_path):
        print('Loading IMU data')
        self.file_path = self.csv_file_path(base_path)
        self.sbet_table = pandas.read_csv(
            self.file_path,
            header=0,
            dtype={ self.GPS_COLUMN: float },
            converters=self.SBET_CSV_DTYPES,
        )

    @staticmethod
    def csv_file_path(base_path):
        return os.path.join(
            base_path, SbetFile.SBET_DIR, SbetFile.SBET_CSV_FILE_NAME
        )

    @staticmethod
    def yaw_to_360(yaw):
        return yaw + 360 if yaw < 0 else yaw

    def get_gps_day_of_week(self, first_entry=True):
        """
        Get GPS day based on entries in the loaded SBET file. Default is to
        calculate the day based on the first day. If parameter is given as
        False the last entry will be used to calculate the day of the week.

        :param first_entry: Default True, whether to use the first day

        :return: Number of seconds for calculated day
        """
        if first_entry:
            sbet_entry = self.sbet_table.iloc[0][self.GPS_COLUMN]
        else:
            sbet_entry = self.sbet_table.iloc[-1][self.GPS_COLUMN]

        days = datetime.timedelta(seconds=float(sbet_entry)).days
        return datetime.timedelta(days=days).total_seconds()

    def find_sbet_record(self, row_time):
        time = self.sbet_table[
            (self.sbet_table[
                 self.GPS_COLUMN] > row_time - self.GPS_TIME_WINDOW) &
            (self.sbet_table[self.GPS_COLUMN] < row_time + self.GPS_TIME_WINDOW)
            ]

        min_diff = (abs(time[self.GPS_COLUMN] - row_time))

        if len(min_diff) == 0:
            return []

        return self.sbet_table.iloc[min_diff.idxmin()]

    @staticmethod
    def update_row(row, values):
        for key, value in zip(ImagesMetaCsv.RESULT_KEYS, values):
            row[key] = value
        return row

    def gps_week_time_for_row(self, row, first_entry=True):
        return self.get_gps_day_of_week(first_entry) + \
               row.get(ImagesMetaCsv.TIME_COLUMN) + \
               self.GPS_LEAP_SECONDS

    def imu_data_for_row(self, row):
        gps_week_time = self.gps_week_time_for_row(row)

        sbet_record = self.find_sbet_record(gps_week_time)
        if len(sbet_record) == 0:
            gps_week_time = self.gps_week_time_for_row(row, False)
            sbet_record = self.find_sbet_record(gps_week_time)

        return sbet_record, gps_week_time

    def set_imu_data_for_row(self, row):
        sbet_record, gps_week_time = self.imu_data_for_row(row)

        if len(sbet_record) > 0:
            result = [
                row.get(ImagesMetaCsv.FILE_COLUMN),
                sbet_record.X,
                sbet_record.Y,
                sbet_record.Z,
                self.yaw_to_360(sbet_record.Heading),
                sbet_record.Pitch,
                sbet_record.Roll,
                gps_week_time - sbet_record[self.GPS_COLUMN],
                row.get(ImagesMetaCsv.TIME_COLUMN),
                row.get(ImagesMetaCsv.TIME_OF_DAY)
            ]
        else:
            result = []

        return self.update_row(row, result)

    def set_altitude_for_row(self, row):
        sbet_record, gps_week_time = self.imu_data_for_row(row)
        row['Z'] = sbet_record.Z
