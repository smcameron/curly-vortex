/*
 *      Copyright (C) 2014 Stephen M. Cameron
 *      Author: Stephen M. Cameron
 *
 *      This file is part of curly-vortex.
 *
 *      curly-vortex is free software; you can redistribute it and/or modify
 *      it under the terms of the GNU General Public License as published by
 *      the Free Software Foundation; either version 2 of the License, or
 *      (at your option) any later version.
 *
 *      curly-vortex is distributed in the hope that it will be useful,
 *      but WITHOUT ANY WARRANTY; without even the implied warranty of
 *      MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *      GNU General Public License for more details.
 *
 *      You should have received a copy of the GNU General Public License
 *      along with curly-vortex if not, write to the Free Software
 *      Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

/*
 * This work is based on the paper "Curl-Noise for Procedural Fluid Flow"
 * by Bridson, Hourihan, and Nordenstam.
 * 
 * See: https://www.cct.lsu.edu/~fharhad/ganbatte/siggraph2007/CD2/content/papers/046-bridson.pdf
 */

int xdim = 400;
int ydim = 400;
float c;

PImage img;

void setup()
{
	size(xdim, ydim);
	frameRate(30);
	img = createImage(xdim, ydim, RGB); 
	img.loadPixels();
	for (int j = 0; j < img.pixels.length; j++) {
		img.pixels[j] = color(0, 0, 0);
	}
	img.updatePixels();
	c = 1.3;
}

void draw()
{ 
	int x, y, r, g, b;
	float nscale = 2.0;
	float amp = 100.0;
	float fx1, fy1, fx2, fy2, n1, n2, nx, ny, v, dx, dy;

	for (x = 0; x < xdim; x++) {
		for (y = 0; y < ydim; y++) {
			dx =  (random(100) * 0.005) - 0.25;
			dy =  (random(100) * 0.005) - 0.25;
			fx1 = ((float(x - 1) + dx) / float(xdim)) * nscale;
			fy1 = ((float(y - 1) + dy) / float(ydim)) * nscale;
			dx =  (random(100) * 0.005) - 0.25;
			dy =  (random(100) * 0.005) - 0.25;
			fx2 = ((float(x + 1) + dx) / float(xdim)) * nscale;
			fy2 = ((float(y + 1) + dy) / float(ydim)) * nscale;
			n1 = noise(fx1, fy1, c);
			n2 = noise(fx2, fy1, c);
			nx = amp * (n2 - n1);
			n1 = noise(fx1, fy1, c);
			n2 = noise(fx1, fy2, c);
			ny = amp * (n2 - n1);
			v = sqrt(nx * nx + ny * ny);
			r = int(v * 255.0);
			if (r > 255)
				r = 255;
			g = r;
			b = r;
			img.set(x, y, color(r, g, b));
		}
	}
	image(img, 0, 0);
	c = c + 0.005;
} 

