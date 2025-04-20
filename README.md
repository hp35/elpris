# ELPRIS - logging the price of electricity in Scandinavia

The `elpris` project uses a Raspberry Pi Zero W and a Pimoroni Inky pHAT 2.13"
display for the continuous logging of the current price for electricity.

## The API used for fetching spot price of electricity

Before proceeding with the instructions for installation and configuration,
let's just mention a few words about the way data for the spot price is
fetched. The application, which is written in Python, makes use of the free
API at https://www.elprisetjustnu.se/elpris-api, with the syntax simply being

  `https://www.elprisetjustnu.se/api/v1/prices/[YEAR]/[MONTH]-[DAY]_[ZONE].json`

where

| Variable | Description                                       | Example |
|----------|---------------------------------------------------|---------|
|  YEAR    | Four digits                                       |    2025 |
|  MONTH   | Always two digits, with leading zero              |      04 |
|  DAY     | Always two digits, with leading zero              |      20 |
|  ZONE    |   SE1 = Luleå / Norra Sverige                     |         |
|          |   SE2 = Sundsvall / Norra Mellansverige           |         |
|          |   SE3 = Gotland / Stockholm / Södra Mellansverige |         |
|          |   SE4 = Malmö / Södra Sverige                     |  SE3    |

As an example, to fetch today's spot price of electricity at Gotland, Sweden
(April 20, 2025, zone SE3), simply use the call

     `GET https://www.elprisetjustnu.se/api/v1/prices/2025/04-20_SE3.json`

# References

  [1] Raspberry Pi Zero W (Retrieved April 20, 2025),
      https://www.raspberrypi.com/products/raspberry-pi-zero-w
      https://www.electrokit.com/raspberry-pi-zero-wh-kort-med-inlodd-header

  [2] Inky pHAT (ePaper/eInk/EPD) by Pimoroni (Retrieved April 20, 2025),
      https://shop.pimoroni.com/products/inky-phat
      https://www.electrokit.com/inky-phat-svart/vit/gul
