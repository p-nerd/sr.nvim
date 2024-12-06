package main

import (
	"image"
	"image/color/palette"
	"image/draw"
	"image/gif"
	"image/jpeg"
	"image/png"
	"log"
	"os"
	"path/filepath"
	"sort"
)

func main() {
	inputDir := "/Users/shihab/Desktop/sr.nvim-gif"
	outputFile := "sr-nvim.gif"
	delay := 50

	files, err := os.ReadDir(inputDir)
	if err != nil {
		log.Fatal(err)
	}

	var filePaths []string
	for _, file := range files {
		if filepath.Ext(file.Name()) == ".jpg" || filepath.Ext(file.Name()) == ".png" {
			filePaths = append(filePaths, filepath.Join(inputDir, file.Name()))
		}
	}
	sort.Strings(filePaths)

	outGif := &gif.GIF{}

	for _, path := range filePaths {
		f, err := os.Open(path)
		if err != nil {
			log.Printf("Error opening %s: %v", path, err)
			continue
		}
		defer f.Close()

		var img image.Image
		switch filepath.Ext(path) {
		case ".jpg", ".jpeg":
			img, err = jpeg.Decode(f)
		case ".png":
			img, err = png.Decode(f)
		}
		if err != nil {
			log.Printf("Error decoding %s: %v", path, err)
			continue
		}

		palettedImg := image.NewPaletted(img.Bounds(), palette.Plan9)
		draw.Draw(palettedImg, palettedImg.Bounds(), img, img.Bounds().Min, draw.Src)

		outGif.Image = append(outGif.Image, palettedImg)
		outGif.Delay = append(outGif.Delay, delay)
	}

	f, err := os.OpenFile(outputFile, os.O_WRONLY|os.O_CREATE, 0600)
	if err != nil {
		log.Fatal(err)
	}
	defer f.Close()

	err = gif.EncodeAll(f, outGif)
	if err != nil {
		log.Fatal(err)
	}
}
